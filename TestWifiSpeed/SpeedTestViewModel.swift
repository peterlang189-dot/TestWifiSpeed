import Foundation

@MainActor
final class SpeedTestViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case running(SpeedTestProgress)
        case completed(SpeedTestResult)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var history: [SpeedTestResult] = []

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
        task = Task {
            do {
                let result = try await runner.run { [weak self] progress in
                    self?.state = .running(progress)
                }
                history.insert(result, at: 0)
                history = Array(history.prefix(8))
                state = .completed(result)
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

    func primaryResult() -> SpeedTestResult? {
        switch state {
        case .completed(let result):
            return result
        default:
            return history.first
        }
    }

    func statusTitle(language: AppLanguage) -> String {
        switch state {
        case .idle:
            return L10n.text("status.ready", language: language)
        case .running:
            return L10n.text("status.running", language: language)
        case .completed:
            return L10n.text("status.finished", language: language)
        case .failed:
            return L10n.text("status.failed", language: language)
        }
    }

    func progressValue() -> Double {
        if case .running(let progress) = state {
            return progress.fraction
        }
        if case .completed = state {
            return 1
        }
        return 0
    }

    func progressMessage(language: AppLanguage) -> String {
        if case .running(let progress) = state {
            return L10n.text(progress.messageKey, language: language)
        }
        if case .failed(let message) = state {
            return message.isEmpty ? L10n.text("error.generic", language: language) : message
        }
        return L10n.text("app.subtitle", language: language)
    }
}
