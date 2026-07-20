import Combine
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
    @Published private(set) var isNetworkAvailable = true
    @Published private(set) var connectionType: NetworkMonitor.ConnectionType = .unknown

    private let runner: SpeedTestRunner
    private let monitor: NetworkMonitor
    private let userDefaults: UserDefaults
    private let runGate: SpeedTestRunGate
    private var task: Task<Void, Never>?
    private var activeRunID: UUID?
    private var cancellables = Set<AnyCancellable>()

    private static let historyKey = "SpeedTestHistory"

    init(
        runner: SpeedTestRunner = SpeedTestRunner(),
        monitor: NetworkMonitor = NetworkMonitor(),
        userDefaults: UserDefaults = .standard,
        runGate: SpeedTestRunGate = SpeedTestRunGate()
    ) {
        self.runner = runner
        self.monitor = monitor
        self.userDefaults = userDefaults
        self.runGate = runGate
        loadHistory()
        observeNetwork()
    }

    // MARK: - Network Observation

    private func observeNetwork() {
        monitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isNetworkAvailable = connected
            }
            .store(in: &cancellables)

        monitor.$connectionType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionType in
                self?.connectionType = connectionType
            }
            .store(in: &cancellables)
    }

    // MARK: - Persistence

    private func loadHistory() {
        guard let data = userDefaults.data(forKey: Self.historyKey) else { return }
        do {
            history = try JSONDecoder().decode([SpeedTestResult].self, from: data)
        } catch {
            history = []
        }
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            userDefaults.set(data, forKey: Self.historyKey)
        } catch {
            // Non-critical: history will be saved on next successful test.
        }
    }

    // MARK: - Actions

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
        state = .running(SpeedTestProgress(stage: .latency, fraction: 0.05, messageKey: "progress.latency"))

        task = Task {
            do {
                let result = try await runner.run { [weak self] progress in
                    guard self?.activeRunID == runID else { return }
                    self?.state = .running(progress)
                }
                try Task.checkCancellation()
                guard activeRunID == runID else { return }
                history.insert(result, at: 0)
                history = Array(history.prefix(SpeedTestThreshold.maxHistoryCount))
                saveHistory()
                state = .completed(result)
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

    func clearHistory() {
        history.removeAll()
        userDefaults.removeObject(forKey: Self.historyKey)
    }

    // MARK: - Queries

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
