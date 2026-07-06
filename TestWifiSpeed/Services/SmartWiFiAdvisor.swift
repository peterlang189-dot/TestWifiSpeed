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
    private var task: Task<Void, Never>?

    init(runner: SpeedTestRunner = SpeedTestRunner()) {
        self.runner = runner
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    func start() {
        guard !isRunning else { return }
        state = .running(nil)
        task = Task {
            do {
                let result = try await runner.run { [weak self] progress in
                    self?.state = .running(progress)
                }
                state = .completed(result, SmartWiFiRecommendation(result: result))
            } catch is CancellationError {
                state = .idle
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        state = .idle
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
