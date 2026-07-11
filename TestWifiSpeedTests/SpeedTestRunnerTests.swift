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

    func testRunnerRejectsInvalidConfiguration() async {
        let configuration = SpeedTestConfiguration(
            latencyURL: URL(string: "https://example.com/latency")!,
            downloadURL: URL(string: "https://example.com/download")!,
            uploadURL: URL(string: "https://example.com/upload")!,
            latencySampleCount: 0,
            uploadBytes: 4_000_000
        )
        let runner = SpeedTestRunner(configuration: configuration, client: MockTransferClient(measurements: []))

        do {
            _ = try await runner.run { _ in }
            XCTFail("Expected invalid configuration to throw")
        } catch let error as SpeedTestError {
            XCTAssertEqual(error, .invalidConfiguration)
        } catch {
            XCTFail("Expected SpeedTestError.invalidConfiguration, got \(error)")
        }
    }

    func testRunnerHonorsCancellationAfterClientReturns() async throws {
        let configuration = SpeedTestConfiguration(
            latencyURL: URL(string: "https://example.com/latency")!,
            downloadURL: URL(string: "https://example.com/download")!,
            uploadURL: URL(string: "https://example.com/upload")!,
            latencySampleCount: 1,
            uploadBytes: 4_000_000
        )
        let client = CancellationIgnoringClient(measurement: TransferMeasurement(bytes: 12, duration: 0.020))
        let runner = SpeedTestRunner(configuration: configuration, client: client)

        let task = Task {
            try await runner.run { _ in }
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation to throw")
        } catch is CancellationError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testDefaultLanguageIsEnglish() {
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(L10n.text("action.start", language: .english), "Start test")
    }

    func testHistoryClearStringsAreLocalized() {
        XCTAssertEqual(L10n.text("history.clear", language: .english), "Clear")
        XCTAssertEqual(L10n.text("history.clear", language: .simplifiedChinese), "清除")
        XCTAssertNotEqual(
            L10n.text("history.clear.confirm.message", language: .english),
            "history.clear.confirm.message"
        )
    }

    @MainActor
    func testViewModelClearsLoadedHistoryAndPersistentStorage() throws {
        let suiteName = "SpeedTestRunnerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let result = SpeedTestResult(
            measuredAt: Date(),
            latencyMs: 24,
            jitterMs: 3,
            downloadMbps: 120,
            uploadMbps: 35,
            grade: .excellent
        )
        defaults.set(try JSONEncoder().encode([result]), forKey: "SpeedTestHistory")

        let viewModel = SpeedTestViewModel(userDefaults: defaults)
        XCTAssertEqual(viewModel.history, [result])

        viewModel.clearHistory()

        XCTAssertTrue(viewModel.history.isEmpty)
        XCTAssertNil(defaults.data(forKey: "SpeedTestHistory"))
    }
}

private actor CancellationIgnoringClient: TransferClient {
    let measurement: TransferMeasurement

    init(measurement: TransferMeasurement) {
        self.measurement = measurement
    }

    func perform(_ request: URLRequest, expectedUploadBytes: Int?) async throws -> TransferMeasurement {
        try? await Task.sleep(nanoseconds: 10_000_000)
        return measurement
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
