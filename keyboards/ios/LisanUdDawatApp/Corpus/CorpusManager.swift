import Foundation

// Manages explicit-consent corpus contribution.
// Unlike the federated weight pipeline (which never transmits text),
// corpus contribution uploads actual word pairs.  Consent is separate,
// granular, and revocable: users review every pair before it is sent.

@MainActor
final class CorpusManager: ObservableObject {

    static let shared = CorpusManager()

    // MARK: - Consent state

    enum ConsentState: String {
        case undecided   // user hasn't been asked yet
        case granted     // user opted in
        case declined    // user opted out — never ask again
    }

    private static let appGroupID = "group.com.yourorg.LisanUdDawat"
    private let defaults = UserDefaults(suiteName: CorpusManager.appGroupID)!
    private let kConsent    = "corpus_consent"
    private let kLastUpload = "corpus_last_upload"

    var consentState: ConsentState {
        get {
            ConsentState(rawValue: defaults.string(forKey: kConsent) ?? "") ?? .undecided
        }
        set { defaults.set(newValue.rawValue, forKey: kConsent) }
    }

    @Published private(set) var pendingReviewCount: Int = 0
    @Published private(set) var totalContributed: Int  = 0
    @Published private(set) var lastUploadDate: Date?

    // MARK: - Aggregator endpoint

    var corpusUploadURL: URL = URL(string: "https://your-aggregator.example.com/corpus")!

    // MARK: - Init

    private init() { reload() }

    func reload() {
        pendingReviewCount = pendingReview().count
        totalContributed   = defaults.integer(forKey: "corpus_total_contributed")
        lastUploadDate     = defaults.object(forKey: kLastUpload) as? Date
    }

    // MARK: - Pair staging
    // Pairs land here from PairCollector; they sit in a "pending review"
    // queue until the user explicitly approves or discards them.

    private let stageKey = "corpus_staged_pairs"

    struct StagedPair: Codable, Identifiable {
        let id: UUID
        let lsd: String
        let roman: String
        let capturedAt: Date
        var approved: Bool?   // nil = unreviewed, true = approved, false = discarded
    }

    func stage(lsd: String, roman: String) {
        guard consentState == .granted else { return }
        var pairs = staged()
        pairs.append(StagedPair(id: UUID(), lsd: lsd, roman: roman, capturedAt: Date(), approved: nil))
        save(staged: pairs)
        pendingReviewCount = pendingReview().count
    }

    func staged() -> [StagedPair] {
        guard let data = defaults.data(forKey: stageKey),
              let pairs = try? JSONDecoder().decode([StagedPair].self, from: data)
        else { return [] }
        return pairs
    }

    func pendingReview() -> [StagedPair] {
        staged().filter { $0.approved == nil }
    }

    func approvedPending() -> [StagedPair] {
        staged().filter { $0.approved == true }
    }

    // User approves a specific pair from the review screen
    func approve(id: UUID) {
        update(id: id) { $0.approved = true }
    }

    // User discards a pair — it will never be uploaded
    func discard(id: UUID) {
        update(id: id) { $0.approved = false }
    }

    // Approve everything currently in the pending queue at once
    func approveAll() {
        var pairs = staged()
        for i in pairs.indices where pairs[i].approved == nil {
            pairs[i].approved = true
        }
        save(staged: pairs)
        reload()
    }

    // Discard everything currently pending
    func discardAll() {
        var pairs = staged()
        for i in pairs.indices where pairs[i].approved == nil {
            pairs[i].approved = false
        }
        save(staged: pairs)
        reload()
    }

    // Remove all staged pairs (approved or not) — full local wipe
    func deleteAllStaged() {
        defaults.removeObject(forKey: stageKey)
        reload()
    }

    // MARK: - Upload

    func uploadApproved() async throws {
        let approved = approvedPending()
        guard !approved.isEmpty else { return }

        let payload = approved.map { ["lsd": $0.lsd, "roman": $0.roman] }
        let body = try JSONSerialization.data(withJSONObject: ["pairs": payload])

        var req = URLRequest(url: corpusUploadURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_, resp) = try await URLSession.shared.upload(for: req, from: body)

        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Mark uploaded pairs as approved=false (done) so they don't re-upload
        let uploadedIDs = Set(approved.map(\.id))
        var pairs = staged()
        for i in pairs.indices where uploadedIDs.contains(pairs[i].id) {
            pairs[i].approved = false  // false = handled
        }
        save(staged: pairs)

        let newTotal = (defaults.integer(forKey: "corpus_total_contributed")) + approved.count
        defaults.set(newTotal, forKey: "corpus_total_contributed")
        defaults.set(Date(), forKey: kLastUpload)
        reload()
    }

    // MARK: - Helpers

    private func update(id: UUID, mutation: (inout StagedPair) -> Void) {
        var pairs = staged()
        if let i = pairs.firstIndex(where: { $0.id == id }) {
            mutation(&pairs[i])
        }
        save(staged: pairs)
        reload()
    }

    private func save(staged: [StagedPair]) {
        let data = try? JSONEncoder().encode(staged)
        defaults.set(data, forKey: stageKey)
    }
}
