import SwiftUI

@main
struct TestWifiSpeedApp: App {
    @AppStorage("appearanceMode") private var appearanceCode = AppearanceMode.system.rawValue
    @StateObject private var batteryHealthViewModel = BatteryHealthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(batteryHealthViewModel)
                .preferredColorScheme(AppearanceMode(rawValue: appearanceCode)?.colorScheme)
        }
    }
}
