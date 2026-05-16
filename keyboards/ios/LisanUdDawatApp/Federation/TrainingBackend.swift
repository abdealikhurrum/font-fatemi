import Foundation

// Abstracts the on-device fine-tuning step.
// The implementation here uses ONNX Runtime (onnxruntime-objc) which supports
// on-device training for the seq2seq model exported from Python.
// If ONNX Runtime is not linked, falls back to a stub that packages pairs
// as a local file for the companion Python script to process.

final class TrainingBackend {

    static let shared = TrainingBackend()
    private init() {}

    // MARK: - Model paths (in app's Documents dir)

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var modelURL:     URL { documentsURL.appendingPathComponent("lsd_model.onnx") }
    private var baseModelURL: URL { documentsURL.appendingPathComponent("lsd_model_base.onnx") }

    // MARK: - Weight delta computation

    // Returns a binary blob representing the weight DELTA (fine_tuned - base).
    // This is what gets uploaded to the aggregator — not the pairs themselves.
    func computeWeightDelta(
        pairs: [(lsd: String, roman: String)]
    ) async throws -> Data {
        // If the ONNX training model is present, use it.
        // Otherwise fall back to the stub (useful during development).
        if FileManager.default.fileExists(atPath: modelURL.path) {
            return try await onnxFineTune(pairs: pairs)
        } else {
            return try stubDelta(pairs: pairs)
        }
    }

    // Install a newly downloaded merged model from the aggregator.
    func installModel(_ data: Data) throws {
        // Keep previous model as the new base before overwriting
        if FileManager.default.fileExists(atPath: modelURL.path) {
            _ = try? FileManager.default.replaceItemAt(baseModelURL, withItemAt: modelURL)
        }
        try data.write(to: modelURL, options: .atomic)
    }

    // MARK: - ONNX fine-tuning

    // Uses onnxruntime-training (onnxruntime-objc package).
    // The training artifacts (model + optimizer state) are produced by:
    //   python tools/export_training_artifacts.py
    // and bundled with the app or downloaded on first launch.
    private func onnxFineTune(
        pairs: [(lsd: String, roman: String)]
    ) async throws -> Data {
        return try await Task.detached(priority: .userInitiated) {
            // -----------------------------------------------------------
            // Pseudo-code — fill in once onnxruntime-objc is linked.
            // The real API mirrors the Python ORT Training API closely.
            //
            // let session = try ORTTrainingSession(
            //     checkpoint: self.checkpointURL,
            //     trainModel:  self.trainModelURL,
            //     evalModel:   self.evalModelURL,
            //     optimizerModel: self.optimizerURL
            // )
            // for epoch in 0..<3 {
            //     for batch in pairs.chunked(into: 8) {
            //         let inputs  = try self.encode(batch.map(\.lsd))
            //         let labels  = try self.encode(batch.map(\.roman))
            //         try session.trainStep(inputs: [inputs, labels])
            //         try session.optimizerStep()
            //         try session.schedulerStep()
            //     }
            // }
            // let delta = try session.exportWeightDelta(relativeTo: self.baseModelURL)
            // return delta
            // -----------------------------------------------------------
            throw TrainingError.onnxRuntimeNotLinked
        }.value
    }

    // MARK: - Stub / Python-companion fallback

    // Packages the pairs as a local JSON file that the companion Python script
    // (tools/local_finetune.py) can pick up via iCloud Drive or USB file sharing.
    // Returns a dummy empty delta so the upload path is still exercised.
    private func stubDelta(pairs: [(lsd: String, roman: String)]) throws -> Data {
        let payload = pairs.map { ["lsd": $0.lsd, "roman": $0.roman] }
        let jsonData = try JSONSerialization.data(
            withJSONObject: ["pairs": payload, "timestamp": Date().timeIntervalSince1970],
            options: .prettyPrinted
        )

        // Write to the shared iCloud Drive folder if available, else Documents
        let exportURL = iCloudExportURL()
            ?? documentsURL.appendingPathComponent("lsd_pairs_export.json")
        try jsonData.write(to: exportURL, options: .atomic)

        // Return empty data — caller should use the Python script path instead
        return Data()
    }

    private func iCloudExportURL() -> URL? {
        guard let iCloud = FileManager.default
            .url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
        else { return nil }
        return iCloud.appendingPathComponent("lsd_pairs_export.json")
    }
}

// MARK: - Errors

enum TrainingError: LocalizedError {
    case onnxRuntimeNotLinked
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .onnxRuntimeNotLinked:
            return "ONNX Runtime not linked. Use the Python companion script instead."
        case .encodingFailed:
            return "Failed to encode input for the model."
        }
    }
}
