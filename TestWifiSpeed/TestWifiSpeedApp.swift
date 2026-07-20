import SwiftUI

@main
struct TestWifiSpeedApp: App {
    @AppStorage("appearanceMode") private var appearanceCode = AppearanceMode.system.rawValue
    @StateObject private var batteryHealthViewModel = BatteryHealthViewModel()
    private let speedTestRunGate = SpeedTestRunGate()

    var body: some Scene {
        WindowGroup {
            ContentView(runGate: speedTestRunGate)
                .environmentObject(batteryHealthViewModel)
                .preferredColorScheme(AppearanceMode(rawValue: appearanceCode)?.colorScheme)
        }
    }
}
