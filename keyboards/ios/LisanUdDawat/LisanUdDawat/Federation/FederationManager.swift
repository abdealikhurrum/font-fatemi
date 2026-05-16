import Foundation
import BackgroundTasks
import Combine

// Central controller for the federated learning pipeline.
// Owns the full lifecycle: read pairs → fine-tune locally → upload delta → pull merged model.
// All text stays on-device. Only the weight delta file is transmitted.

@MainActor
final class FederationManager: ObservableObject {

    static let shared = FederationManager()

    // MARK: - Published state (drives the Settings UI)

    @Published private(set) var pendingPairCount: Int = 0
    @Published private(set) var lastPushDate: Date?
    @Published private(set) var lastPullDate: Date?
    @Published private(set) var remoteModelVersion: String = "none"
    @Published private(set) var localModelVersion: String  = "none"
    @Published private(set) var status: Status = .idle

    enum Status: Equatable {
        case idle
        case training
        case uploading
        case downloading
        case error(String)
    }

    // MARK: - Configuration (adjust per deployment)

    struct Config {
        // Base URL of the aggregator server (see aggregator/server.py)
        var aggregatorURL: URL = URL(string: "https://your-aggregator.example.com")!
        // Minimum new pairs before auto-push fires
        var autoPushThreshold: Int = 50
        // Background task identifiers — register these in Info.plist
        var bgPushTaskID: String = "com.yourorg.LisanUdDawat.federation.push"
        var bgPullTaskID: String = "com.yourorg.LisanUdDawat.federation.pull"
    }

    var config = Config()

    // MARK: - Persistence keys

    private let defaults = UserDefaults(suiteName: PairCollector.appGroupID)!
    private let kLastPushDate    = "fed_last_push"
    private let kLastPullDate    = "fed_last_pull"
    private let kLocalVersion    = "fed_local_model_version"
    private let kAutoPushEnabled = "fed_auto_push_enabled"

    var autoPushEnabled: Bool {
        get { defaults.bool(forKey: kAutoPushEnabled) }
        set {
            defaults.set(newValue, forKey: kAutoPushEnabled)
            newValue ? scheduleBackgroundTasks() : cancelBackgroundTasks()
        }
    }

    // MARK: - Init

    private init() {
        reload()
    }

    func reload() {
        pendingPairCount   = PairCollector.shared.pendingCount()
        lastPushDate       = defaults.object(forKey: kLastPushDate) as? Date
        lastPullDate       = defaults.object(forKey: kLastPullDate) as? Date
        localModelVersion  = defaults.string(forKey: kLocalVersion) ?? "base"
    }

    // MARK: - Manual push

    func pushNow() async {
        guard status == .idle else { return }

        let pairs = PairCollector.shared.fetchPending()
        guard !pairs.isEmpty else { return }

        // 1. Train locally and produce a weight delta
        status = .training
        let delta: Data
        do {
            delta = try await TrainingBackend.shared.computeWeightDelta(
                pairs: pairs.map { (lsd: $0.lsd, roman: $0.roman) }
            )
        } catch {
            status = .error("Training failed: \(error.localizedDescription)")
            return
        }

        // 2. Upload the delta (never the pairs themselves)
        status = .uploading
        do {
            try await upload(delta: delta)
            let ids = pairs.map(\.id)
            PairCollector.shared.markContributed(ids: ids)
            defaults.set(Date(), forKey: kLastPushDate)
            lastPushDate = Date()
            pendingPairCount = PairCollector.shared.pendingCount()
        } catch {
            status = .error("Upload failed: \(error.localizedDescription)")
            return
        }

        status = .idle
    }

    // MARK: - Pull latest model

    func pullLatest() async {
        guard status == .idle else { return }
        status = .downloading
        do {
            let info = try await fetchRemoteModelInfo()
            remoteModelVersion = info.version
            if info.version != localModelVersion {
                let modelData = try await downloadModel(url: info.url)
                try TrainingBackend.shared.installModel(modelData)
                localModelVersion = info.version
                defaults.set(info.version, forKey: kLocalVersion)
                defaults.set(Date(), forKey: kLastPullDate)
                lastPullDate = Date()
            }
        } catch {
            status = .error("Pull failed: \(error.localizedDescription)")
            return
        }
        status = .idle
    }

    // MARK: - Background task scheduling (BGTaskScheduler)

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: config.bgPushTaskID, using: nil
        ) { [weak self] task in
            self?.handleBackgroundPush(task: task as! BGProcessingTask)
        }
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: config.bgPullTaskID, using: nil
        ) { [weak self] task in
            self?.handleBackgroundPull(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundTasks() {
        schedulePush()
        schedulePull()
    }

    func cancelBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: config.bgPushTaskID)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: config.bgPullTaskID)
    }

    // Push fires overnight when charging — gives the training enough time
    private func schedulePush() {
        let req = BGProcessingTaskRequest(identifier: config.bgPushTaskID)
        req.requiresNetworkConnectivity = true
        req.requiresExternalPower = true                          // charging only
        req.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // at least 1h from now
        try? BGTaskScheduler.shared.submit(req)
    }

    // Pull fires on background app refresh (lower power requirement)
    private func schedulePull() {
        let req = BGAppRefreshTaskRequest(identifier: config.bgPullTaskID)
        req.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600) // every 6h
        try? BGTaskScheduler.shared.submit(req)
    }

    private func handleBackgroundPush(task: BGProcessingTask) {
        schedulePush() // reschedule immediately for next time

        let shouldPush = autoPushEnabled
            && PairCollector.shared.pendingCount() >= config.autoPushThreshold

        guard shouldPush else { task.setTaskCompleted(success: true); return }

        let pushTask = Task { await pushNow() }
        task.expirationHandler = { pushTask.cancel() }
        Task {
            await pushTask.value
            task.setTaskCompleted(success: status != .error(""))
        }
    }

    private func handleBackgroundPull(task: BGAppRefreshTask) {
        schedulePull()
        let pullTask = Task { await pullLatest() }
        task.expirationHandler = { pullTask.cancel() }
        Task {
            await pullTask.value
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Networking

    private func upload(delta: Data) async throws {
        var req = URLRequest(url: config.aggregatorURL.appendingPathComponent("weights"))
        req.httpMethod = "POST"
        req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        req.setValue(localModelVersion, forHTTPHeaderField: "X-Base-Version")
        let (_, resp) = try await URLSession.shared.upload(for: req, from: delta)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    private struct RemoteModelInfo: Decodable {
        let version: String
        let url: URL
    }

    private func fetchRemoteModelInfo() async throws -> RemoteModelInfo {
        let url = config.aggregatorURL.appendingPathComponent("model/latest")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(RemoteModelInfo.self, from: data)
    }

    private func downloadModel(url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
