import XCTest
@testable import TestWifiSpeed

final class SpeedTestRunnerTests: XCTestCase {
    func testMegabitsPerSecondCalculation() {
        XCTAssertEqual(SpeedMath.megabitsPerSecond(bytes: 1_000_000, duration: 1), 8, accuracy: 0.001)
        XCTAssertEqual(SpeedMath.megabitsPerSecond(bytes: 0, duration: 1), 0)
        XCTAssertEqual(SpeedMath.megabitsPerSecond(bytes: 1_000_000, duration: 0), 0)
    }

    func testJitterUsesAverageAdjacentDelta() {
        XCTAssertEqual(SpeedMath.jitter(from: [20, 25, 18]), 6, accuracy: 0.001)
    }

    func testGradesNetworkQuality() {
        XCTAssertEqual(SpeedMath.grade(downloadMbps: 120, uploadMbps: 40, latencyMs: 20), .excellent)
        XCTAssertEqual(SpeedMath.grade(downloadMbps: 60, uploadMbps: 20, latencyMs: 50), .good)
        XCTAssertEqual(SpeedMath.grade(downloadMbps: 20, uploadMbps: 8, latencyMs: 90), .fair)
        XCTAssertEqual(SpeedMath.grade(downloadMbps: 5, uploadMbps: 1, latencyMs: 180), .poor)
    }

    func testRunnerCombinesLatencyDownloadAndUploadMeasurements() async throws {
        let client = MockTransferClient(measurements: [
            TransferMeasurement(bytes: 12, duration: 0.020),
            TransferMeasurement(bytes: 12, duration: 0.030),
            TransferMeasurement(bytes: 12, duration: 0.025),
            TransferMeasurement(bytes: 12, duration: 0.035),
            TransferMeasurement(bytes: 12, duration: 0.040),
            TransferMeasurement(bytes: 10_000_000, duration: 1.0),
            TransferMeasurement(bytes: 4_000_000, duration: 2.0)
        ])

        let runner = SpeedTestRunner(client: client)
        var progressEvents: [SpeedTestProgress] = []

        let result = try await runner.run { progress in
            progressEvents.append(progress)
        }

        XCTAssertEqual(result.latencyMs, 30, accuracy: 0.001)
        XCTAssertEqual(result.jitterMs, 7.5, accuracy: 0.001)
        XCTAssertEqual(result.downloadMbps, 80, accuracy: 0.001)
        XCTAssertEqual(result.uploadMbps, 16, accuracy: 0.001)
        XCTAssertEqual(result.grade, .good)
        XCTAssertEqual(progressEvents.last?.stage, .complete)
    }

    func testDefaultLanguageIsEnglish() {
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(L10n.text("action.start", language: .english), "Start test")
    }
}

private actor MockTransferClient: TransferClient {
    private var measurements: [TransferMeasurement]

    init(measurements: [TransferMeasurement]) {
        self.measurements = measurements
    }

    func perform(_ request: URLRequest, expectedUploadBytes: Int?) async throws -> TransferMeasurement {
        guard !measurements.isEmpty else {
            throw SpeedTestError.noSamples
        }
        return measurements.removeFirst()
    }
}
