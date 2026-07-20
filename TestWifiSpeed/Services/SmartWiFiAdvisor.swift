import SwiftUI

// MARK: - Smart Wi-Fi Recommendation

enum SmartWiFiRecommendation {
    case keep
    case switchSoon
    case switchNow

    init(result: SpeedTestResult) {
        if result.downloadMbps >= SpeedTestThreshold.smartKeepDownload,
           result.uploadMbps >= SpeedTestThreshold.smartKeepUpload,
           result.latencyMs <= SpeedTestThreshold.smartKeepLatency,
           result.jitterMs <= SpeedTestThreshold.smartKeepJitter {
            self = .keep
        } else if result.downloadMbps >= SpeedTestThreshold.smartSwitchDownload,
                  result.uploadMbps >= SpeedTestThreshold.smartSwitchUpload,
                  result.latencyMs <= SpeedTestThreshold.smartSwitchLatency {
            self = .switchSoon
        } else {
            self = .switchNow
        }
    }

    var icon: String {
        switch self {
        case .keep:
            return "checkmark.seal.fill"
        case .switchSoon:
            return "arrow.triangle.2.circlepath"
        case .switchNow:
            return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .keep:
            return .green
        case .switchSoon:
            return .orange
        case .switchNow:
            return .red
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .keep:
            return L10n.text("smart.recommend.keep", language: language)
        case .switchSoon:
            return L10n.text("smart.recommend.switchSoon", language: language)
        case .switchNow:
            return L10n.text("smart.recommend.switchNow", language: language)
        }
    }

    func detail(language: AppLanguage) -> String {
        switch self {
        case .keep:
            return L10n.text("smart.detail.keep", language: language)
        case .switchSoon:
            return L10n.text("smart.detail.switchSoon", language: language)
        case .switchNow:
            return L10n.text("smart.detail.switchNow", language: language)
        }
    }
}

// MARK: - Smart Wi-Fi Advisor ViewModel

@MainActor
final class SmartWiFiAdvisor: ObservableObject {
    enum State {
        case idle
        case running(SpeedTestProgress?)
        case completed(SpeedTestResult, SmartWiFiRecommendation)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    private let runner: SpeedTestRunner
    private let runGate: SpeedTestRunGate
    private var task: Task<Void, Never>?
    private var activeRunID: UUID?

    init(
        runner: SpeedTestRunner = SpeedTestRunner(),
        runGate: SpeedTestRunGate = SpeedTestRunGate()
    ) {
        self.runner = runner
        self.runGate = runGate
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    func start() {
        guard !isRunning else { return }
        let runID = UUID()
        guard runGate.acquire(runID: runID) else {
            state = .failed(SpeedTestError.busy.localizedDescription)
            return
        }
        activeRunID = runID
        state = .running(nil)

        task = Task {
            do {
                let result = try await runner.run { [weak self] progress in
                    guard self?.activeRunID == runID else { return }
                    self?.state = .running(progress)
                }
                try Task.checkCancellation()
                guard activeRunID == runID else { return }
                state = .completed(result, SmartWiFiRecommendation(result: result))
                finish(runID: runID)
            } catch is CancellationError {
                guard activeRunID == runID else { return }
                state = .idle
                finish(runID: runID)
            } catch {
                guard activeRunID == runID else { return }
                state = .failed(error.localizedDescription)
                finish(runID: runID)
            }
        }
    }

    func cancel() {
        if let runID = activeRunID {
            runGate.release(runID: runID)
        }
        activeRunID = nil
        task?.cancel()
        task = nil
        state = .idle
    }

    private func finish(runID: UUID) {
        runGate.release(runID: runID)
        activeRunID = nil
        task = nil
    }

    func progressValue() -> Double {
        switch state {
        case .running(let progress):
            return progress?.fraction ?? 0.05
        case .completed:
            return 1
        default:
            return 0
        }
    }

    func statusText(language: AppLanguage) -> String {
        switch state {
        case .idle:
            return L10n.text("smart.ready", language: language)
        case .running(let progress):
            return L10n.text(progress?.messageKey ?? "smart.scanning", language: language)
        case .completed(_, let recommendation):
            return recommendation.title(language: language)
        case .failed(let message):
            return message.isEmpty ? L10n.text("error.generic", language: language) : message
        }
    }
}
