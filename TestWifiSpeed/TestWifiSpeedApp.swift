import SwiftUI

@main
struct TestWifiSpeedApp: App {
    @AppStorage("appearanceMode") private var appearanceCode = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(AppearanceMode(rawValue: appearanceCode)?.colorScheme)
        }
    }
}
