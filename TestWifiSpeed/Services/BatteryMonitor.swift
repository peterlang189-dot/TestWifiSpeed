import Foundation
import UIKit
import UserNotifications

protocol BatteryMonitoring: AnyObject {
    var currentSnapshot: BatterySnapshot { get }
    func start(onChange: @escaping (BatterySnapshot) -> Void)
    func stop()
}

final class DeviceBatteryMonitor: BatteryMonitoring {
    private let device: UIDevice
    private let notificationCenter: NotificationCenter
    private var observers: [NSObjectProtocol] = []
    private var onChange: ((BatterySnapshot) -> Void)?

    init(
        device: UIDevice = .current,
        notificationCenter: NotificationCenter = .default
    ) {
        self.device = device
        self.notificationCenter = notificationCenter
    }

    var currentSnapshot: BatterySnapshot {
        guard device.isBatteryMonitoringEnabled, device.batteryLevel >= 0 else {
            return .unavailable
        }

        return BatterySnapshot(
            level: Int((device.batteryLevel * 100).rounded()),
            state: powerState(from: device.batteryState)
        )
    }

    func start(onChange: @escaping (BatterySnapshot) -> Void) {
        stop()
        self.onChange = onChange
        device.isBatteryMonitoringEnabled = true

        let names: [Notification.Name] = [
            UIDevice.batteryLevelDidChangeNotification,
            UIDevice.batteryStateDidChangeNotification
        ]
        observers = names.map { name in
            notificationCenter.addObserver(
                forName: name,
                object: device,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.onChange?(self.currentSnapshot)
            }
        }

        onChange(currentSnapshot)
    }

    func stop() {
        observers.forEach(notificationCenter.removeObserver)
        observers.removeAll()
        onChange = nil
    }

    deinit {
        stop()
    }

    private func powerState(from state: UIDevice.BatteryState) -> BatteryPowerState {
        switch state {
        case .unplugged:
            return .unplugged
        case .charging:
            return .charging
        case .full:
            return .full
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}

protocol ChargeControlling {
    var canStopCharging: Bool { get }
    @discardableResult func stopCharging() -> Bool
}

/// iOS exposes battery monitoring but no public API that lets an App Store app
/// disconnect charging hardware. Returning false keeps the UI and tests honest.
struct IOSChargeController: ChargeControlling {
    let canStopCharging = false

    func stopCharging() -> Bool {
        false
    }
}

protocol BatteryThresholdNotifying {
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    func notifyLimitReached(level: Int, threshold: Int, language: AppLanguage)
}

final class LocalBatteryThresholdNotifier: BatteryThresholdNotifying {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func notifyLimitReached(level: Int, threshold: Int, language: AppLanguage) {
        let content = UNMutableNotificationContent()
        content.title = L10n.text("battery.notification.title", language: language)
        content.body = String(
            format: L10n.text("battery.notification.body", language: language),
            level,
            threshold
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "battery-charge-limit-\(threshold)",
            content: content,
            trigger: nil
        )
        center.add(request, withCompletionHandler: nil)
    }
}
