import XCTest
@testable import TestWifiSpeed

final class BatteryHealthTests: XCTestCase {
    func testDefaultThresholdIsNinetyPercent() {
        XCTAssertEqual(ChargeLimitPolicy.defaultThreshold, 90)
    }

    func testThresholdNormalizationKeepsValuesWithinSupportedRange() {
        XCTAssertEqual(ChargeLimitPolicy.normalizedThreshold(20), 50)
        XCTAssertEqual(ChargeLimitPolicy.normalizedThreshold(82), 82)
        XCTAssertEqual(ChargeLimitPolicy.normalizedThreshold(120), 100)
    }

    func testStateMachineTriggersOnceWhenChargingReachesLimit() {
        var stateMachine = ChargeLimitStateMachine()

        XCTAssertEqual(
            stateMachine.process(
                snapshot: BatterySnapshot(level: 89, state: .charging),
                isEnabled: true,
                threshold: 90
            ),
            .none
        )
        XCTAssertEqual(
            stateMachine.process(
                snapshot: BatterySnapshot(level: 90, state: .charging),
                isEnabled: true,
                threshold: 90
            ),
            .limitReached(level: 90)
        )
        XCTAssertEqual(
            stateMachine.process(
                snapshot: BatterySnapshot(level: 91, state: .charging),
                isEnabled: true,
                threshold: 90
            ),
            .none
        )
    }

    func testStateMachineRearmsAfterUnplugging() {
        var stateMachine = ChargeLimitStateMachine()

        _ = stateMachine.process(
            snapshot: BatterySnapshot(level: 90, state: .charging),
            isEnabled: true,
            threshold: 90
        )
        XCTAssertEqual(
            stateMachine.process(
                snapshot: BatterySnapshot(level: 90, state: .unplugged),
                isEnabled: true,
                threshold: 90
            ),
            .none
        )
        XCTAssertEqual(
            stateMachine.process(
                snapshot: BatterySnapshot(level: 91, state: .charging),
                isEnabled: true,
                threshold: 90
            ),
            .limitReached(level: 91)
        )
    }

    func testDisabledLimitAndUnknownBatteryNeverTrigger() {
        var stateMachine = ChargeLimitStateMachine()

        XCTAssertEqual(
            stateMachine.process(
                snapshot: BatterySnapshot(level: 95, state: .charging),
                isEnabled: false,
                threshold: 90
            ),
            .none
        )
        XCTAssertEqual(
            stateMachine.process(
                snapshot: .unavailable,
                isEnabled: true,
                threshold: 90
            ),
            .none
        )
    }

    func testSimulationStopsExactlyAtLimitWithoutOvershoot() {
        var simulation = BatteryChargeSimulation(level: 87, isCharging: true)

        XCTAssertEqual(
            simulation.advance(percentagePoints: 5, limitEnabled: true, threshold: 90),
            .stoppedAtLimit(level: 90)
        )
        XCTAssertEqual(simulation.level, 90)
        XCTAssertFalse(simulation.isCharging)
    }

    func testSimulationChargesToFullWhenLimitIsDisabled() {
        var simulation = BatteryChargeSimulation(level: 98, isCharging: true)

        XCTAssertEqual(
            simulation.advance(percentagePoints: 5, limitEnabled: false, threshold: 90),
            .full
        )
        XCTAssertEqual(simulation.level, 100)
        XCTAssertFalse(simulation.isCharging)
    }

    @MainActor
    func testViewModelUsesAndPersistsDefaultSettings() throws {
        let suiteName = "BatteryHealthTests.defaults.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let viewModel = BatteryHealthViewModel(
            monitor: MockBatteryMonitor(),
            chargeController: MockChargeController(canStopCharging: false),
            notifier: MockBatteryNotifier(),
            userDefaults: defaults
        )

        XCTAssertTrue(viewModel.isEnabled)
        XCTAssertEqual(viewModel.threshold, 90)

        viewModel.setThreshold(84)
        viewModel.setEnabled(false)

        XCTAssertEqual(defaults.integer(forKey: BatteryHealthViewModel.thresholdKey), 84)
        XCTAssertFalse(defaults.bool(forKey: BatteryHealthViewModel.enabledKey))
    }

    @MainActor
    func testRealIOSPathAlertsButDoesNotClaimChargingStopped() async {
        let monitor = MockBatteryMonitor()
        let controller = MockChargeController(canStopCharging: false)
        let notifier = MockBatteryNotifier()
        let defaults = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }

        let viewModel = BatteryHealthViewModel(
            monitor: monitor,
            chargeController: controller,
            notifier: notifier,
            userDefaults: defaults
        )
        viewModel.updateLanguage(.simplifiedChinese)

        monitor.emit(BatterySnapshot(level: 90, state: .charging))
        await Task.yield()

        XCTAssertEqual(controller.stopCallCount, 1)
        XCTAssertEqual(notifier.notifications.count, 1)
        XCTAssertEqual(notifier.notifications.first?.level, 90)
        XCTAssertEqual(notifier.notifications.first?.threshold, 90)
        XCTAssertEqual(notifier.notifications.first?.language, .simplifiedChinese)
        XCTAssertEqual(viewModel.latestLimitEvent?.chargingWasStopped, false)

        monitor.emit(BatterySnapshot(level: 92, state: .charging))
        await Task.yield()
        XCTAssertEqual(controller.stopCallCount, 1, "A charging session should only alert once")
        XCTAssertEqual(notifier.notifications.count, 1)
    }

    @MainActor
    func testInjectableSimulationControllerStopsWithoutSendingUnplugNotification() async {
        let monitor = MockBatteryMonitor()
        let controller = MockChargeController(canStopCharging: true)
        let notifier = MockBatteryNotifier()
        let defaults = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }

        let viewModel = BatteryHealthViewModel(
            monitor: monitor,
            chargeController: controller,
            notifier: notifier,
            userDefaults: defaults
        )

        monitor.emit(BatterySnapshot(level: 90, state: .charging))
        await Task.yield()

        XCTAssertEqual(controller.stopCallCount, 1)
        XCTAssertTrue(notifier.notifications.isEmpty)
        XCTAssertEqual(viewModel.latestLimitEvent?.chargingWasStopped, true)
    }

    @MainActor
    func testChangingThresholdReevaluatesCurrentChargingLevel() {
        let monitor = MockBatteryMonitor(snapshot: BatterySnapshot(level: 85, state: .charging))
        let controller = MockChargeController(canStopCharging: false)
        let notifier = MockBatteryNotifier()
        let defaults = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }

        let viewModel = BatteryHealthViewModel(
            monitor: monitor,
            chargeController: controller,
            notifier: notifier,
            userDefaults: defaults
        )

        viewModel.setThreshold(85)

        XCTAssertEqual(controller.stopCallCount, 1)
        XCTAssertEqual(viewModel.latestLimitEvent?.threshold, 85)
    }

    func testBatteryCopyIsLocalizedAndTruthfulAboutIOSLimitation() {
        XCTAssertEqual(
            L10n.text("battery.limit.threshold", language: .simplifiedChinese),
            "提醒电量"
        )
        XCTAssertTrue(
            L10n.text("battery.platform.reminderonly", language: .english)
                .contains("no public API")
        )
    }

    @MainActor
    func testViewModelRequestsNotificationPermissionOnLaunchWhenEnabled() {
        let notifier = MockBatteryNotifier()
        let defaults = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }

        _ = BatteryHealthViewModel(
            monitor: MockBatteryMonitor(),
            chargeController: MockChargeController(canStopCharging: false),
            notifier: notifier,
            userDefaults: defaults
        )

        XCTAssertEqual(
            notifier.authorizationRequestCount, 1,
            "Enabled-by-default limit reminders must request authorization up front; otherwise the system silently drops the notification"
        )
    }

    @MainActor
    func testViewModelSkipsPermissionRequestWhenLimitDisabled() {
        let notifier = MockBatteryNotifier()
        let defaults = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        defaults.set(false, forKey: BatteryHealthViewModel.enabledKey)

        _ = BatteryHealthViewModel(
            monitor: MockBatteryMonitor(),
            chargeController: MockChargeController(canStopCharging: false),
            notifier: notifier,
            userDefaults: defaults
        )

        XCTAssertEqual(notifier.authorizationRequestCount, 0)
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "BatteryHealthTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.set(name, forKey: "testSuiteName")
        return defaults
    }

    private func defaultsSuiteName(_ defaults: UserDefaults) -> String {
        defaults.string(forKey: "testSuiteName")!
    }
}

private final class MockBatteryMonitor: BatteryMonitoring {
    private(set) var currentSnapshot: BatterySnapshot
    private var onChange: ((BatterySnapshot) -> Void)?

    init(snapshot: BatterySnapshot = .unavailable) {
        currentSnapshot = snapshot
    }

    func start(onChange: @escaping (BatterySnapshot) -> Void) {
        self.onChange = onChange
        onChange(currentSnapshot)
    }

    func stop() {
        onChange = nil
    }

    func emit(_ snapshot: BatterySnapshot) {
        currentSnapshot = snapshot
        onChange?(snapshot)
    }
}

private final class MockChargeController: ChargeControlling {
    let canStopCharging: Bool
    private(set) var stopCallCount = 0

    init(canStopCharging: Bool) {
        self.canStopCharging = canStopCharging
    }

    func stopCharging() -> Bool {
        stopCallCount += 1
        return canStopCharging
    }
}

private final class MockBatteryNotifier: BatteryThresholdNotifying {
    struct Notification: Equatable {
        let level: Int
        let threshold: Int
        let language: AppLanguage
    }

    private(set) var authorizationRequestCount = 0
    private(set) var notifications: [Notification] = []

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        authorizationRequestCount += 1
        completion(true)
    }

    func notifyLimitReached(level: Int, threshold: Int, language: AppLanguage) {
        notifications.append(Notification(level: level, threshold: threshold, language: language))
    }
}
