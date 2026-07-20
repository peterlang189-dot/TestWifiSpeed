import Combine
import Foundation

struct BatteryLimitEvent: Identifiable, Equatable {
    let id = UUID()
    let level: Int
    let threshold: Int
    let chargingWasStopped: Bool

    static func == (lhs: BatteryLimitEvent, rhs: BatteryLimitEvent) -> Bool {
        lhs.level == rhs.level
            && lhs.threshold == rhs.threshold
            && lhs.chargingWasStopped == rhs.chargingWasStopped
    }
}

@MainActor
final class BatteryHealthViewModel: ObservableObject {
    static let enabledKey = "batteryChargeLimitEnabled"
    static let thresholdKey = "batteryChargeLimitThreshold"

    @Published private(set) var snapshot: BatterySnapshot
    @Published private(set) var isEnabled: Bool
    @Published private(set) var threshold: Int
    @Published private(set) var notificationPermissionGranted: Bool?
    @Published var latestLimitEvent: BatteryLimitEvent?

    private let monitor: BatteryMonitoring
    private let chargeController: ChargeControlling
    private let notifier: BatteryThresholdNotifying
    private let userDefaults: UserDefaults
    private var stateMachine = ChargeLimitStateMachine()
    private var language: AppLanguage = .english

    var canPhysicallyStopCharging: Bool {
        chargeController.canStopCharging
    }

    init(
        monitor: BatteryMonitoring = DeviceBatteryMonitor(),
        chargeController: ChargeControlling = IOSChargeController(),
        notifier: BatteryThresholdNotifying = LocalBatteryThresholdNotifier(),
        userDefaults: UserDefaults = .standard
    ) {
        self.monitor = monitor
        self.chargeController = chargeController
        self.notifier = notifier
        self.userDefaults = userDefaults
        snapshot = monitor.currentSnapshot

        if userDefaults.object(forKey: Self.enabledKey) == nil {
            isEnabled = true
        } else {
            isEnabled = userDefaults.bool(forKey: Self.enabledKey)
        }

        if userDefaults.object(forKey: Self.thresholdKey) == nil {
            threshold = ChargeLimitPolicy.defaultThreshold
        } else {
            threshold = ChargeLimitPolicy.normalizedThreshold(
                userDefaults.integer(forKey: Self.thresholdKey)
            )
        }

        // The limit reminder is on by default; without authorization the
        // system silently drops the notification, so ask up front.
        if isEnabled {
            requestNotificationPermission()
        }

        monitor.start { [weak self] snapshot in
            Task { @MainActor [weak self] in
                self?.receive(snapshot)
            }
        }
    }

    deinit {
        monitor.stop()
    }

    func updateLanguage(_ language: AppLanguage) {
        self.language = language
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        userDefaults.set(enabled, forKey: Self.enabledKey)
        stateMachine.reset()

        if enabled {
            requestNotificationPermission()
            evaluateCurrentSnapshot()
        }
    }

    func setThreshold(_ value: Int) {
        let normalized = ChargeLimitPolicy.normalizedThreshold(value)
        guard threshold != normalized else { return }
        threshold = normalized
        userDefaults.set(normalized, forKey: Self.thresholdKey)
        stateMachine.reset()
        evaluateCurrentSnapshot()
    }

    func requestNotificationPermission() {
        notifier.requestAuthorization { [weak self] granted in
            Task { @MainActor [weak self] in
                self?.notificationPermissionGranted = granted
            }
        }
    }

    func receive(_ snapshot: BatterySnapshot) {
        self.snapshot = snapshot
        evaluateCurrentSnapshot()
    }

    func dismissLatestEvent() {
        latestLimitEvent = nil
    }

    func levelText(unavailable: String) -> String {
        snapshot.level.map { "\($0)%" } ?? unavailable
    }

    private func evaluateCurrentSnapshot() {
        let decision = stateMachine.process(
            snapshot: snapshot,
            isEnabled: isEnabled,
            threshold: threshold
        )

        guard case let .limitReached(level) = decision else { return }

        let didStop = chargeController.stopCharging()
        if !didStop {
            notifier.notifyLimitReached(level: level, threshold: threshold, language: language)
        }
        latestLimitEvent = BatteryLimitEvent(
            level: level,
            threshold: threshold,
            chargingWasStopped: didStop
        )
    }
}
