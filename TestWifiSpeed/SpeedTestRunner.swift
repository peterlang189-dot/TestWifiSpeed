import Foundation

protocol TransferClient {
    func perform(_ request: URLRequest, expectedUploadBytes: Int?) async throws -> TransferMeasurement
}

struct URLSessionTransferClient: TransferClient {
    func perform(_ request: URLRequest, expectedUploadBytes: Int?) async throws -> TransferMeasurement {
        let start = Date.timeIntervalSinceReferenceDate
        let (data, response) = try await URLSession.shared.data(for: request)
        let duration = Date.timeIntervalSinceReferenceDate - start

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<400).contains(httpResponse.statusCode) {
            throw SpeedTestError.badStatusCode(httpResponse.statusCode)
        }

        return TransferMeasurement(
            bytes: expectedUploadBytes ?? data.count,
            duration: max(duration, 0.001)
        )
    }
}

enum SpeedTestError: LocalizedError, Equatable {
    case badStatusCode(Int)
    case noSamples

    var errorDescription: String? {
        switch self {
        case .badStatusCode(let code):
            return "Unexpected server response: \(code)"
        case .noSamples:
            return "Unable to collect network samples."
        }
    }
}

struct SpeedTestRunner {
    let configuration: SpeedTestConfiguration
    let client: TransferClient

    init(
        configuration: SpeedTestConfiguration = .appDefault,
        client: TransferClient = URLSessionTransferClient()
    ) {
        self.configuration = configuration
        self.client = client
    }

    func run(progress: @escaping @MainActor (SpeedTestProgress) -> Void) async throws -> SpeedTestResult {
        await progress(SpeedTestProgress(stage: .latency, fraction: 0.1, messageKey: "progress.latency"))

        var latencySamples: [Double] = []
        for index in 0..<configuration.latencySampleCount {
            try Task.checkCancellation()
            var request = URLRequest(url: configuration.latencyURL)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 10
            request.httpMethod = "GET"

            let measurement = try await client.perform(request, expectedUploadBytes: nil)
            latencySamples.append(measurement.duration * 1_000)

            let fraction = 0.1 + (Double(index + 1) / Double(configuration.latencySampleCount)) * 0.25
            await progress(SpeedTestProgress(stage: .latency, fraction: fraction, messageKey: "progress.latency"))
        }

        guard !latencySamples.isEmpty else {
            throw SpeedTestError.noSamples
        }

        try Task.checkCancellation()
        await progress(SpeedTestProgress(stage: .download, fraction: 0.45, messageKey: "progress.download"))
        var downloadRequest = URLRequest(url: configuration.downloadURL)
        downloadRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        downloadRequest.timeoutInterval = 30
        downloadRequest.httpMethod = "GET"
        let download = try await client.perform(downloadRequest, expectedUploadBytes: nil)

        try Task.checkCancellation()
        await progress(SpeedTestProgress(stage: .upload, fraction: 0.75, messageKey: "progress.upload"))
        var uploadRequest = URLRequest(url: configuration.uploadURL)
        uploadRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        uploadRequest.timeoutInterval = 30
        uploadRequest.httpMethod = "POST"
        uploadRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        uploadRequest.httpBody = Data(repeating: 0x5A, count: configuration.uploadBytes)
        let upload = try await client.perform(uploadRequest, expectedUploadBytes: configuration.uploadBytes)

        let latency = SpeedMath.average(latencySamples)
        let jitter = SpeedMath.jitter(from: latencySamples)
        let downloadMbps = download.megabitsPerSecond
        let uploadMbps = upload.megabitsPerSecond
        let grade = SpeedMath.grade(
            downloadMbps: downloadMbps,
            uploadMbps: uploadMbps,
            latencyMs: latency
        )

        await progress(SpeedTestProgress(stage: .complete, fraction: 1, messageKey: "progress.complete"))

        return SpeedTestResult(
            measuredAt: Date(),
            latencyMs: latency,
            jitterMs: jitter,
            downloadMbps: downloadMbps,
            uploadMbps: uploadMbps,
            grade: grade
        )
    }
}
