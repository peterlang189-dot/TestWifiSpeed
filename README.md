# Test WiFi Speed

Test WiFi Speed is a SwiftUI iOS app for measuring network latency, jitter, download speed, and upload speed. The app is designed for App Store submission with public APIs, a privacy manifest, English-first localization, Simplified Chinese support, and light/dark appearance controls.

## Features

- Real HTTPS-based speed test using public endpoints
- Latency, jitter, download, upload, and quality grade
- Local-only recent test history
- English by default, with Simplified Chinese available in app settings
- System, light, and dark appearance modes
- Privacy screen and `PrivacyInfo.xcprivacy` declaring no tracking and no collected data
- Unit tests for speed calculations, grading, localization defaults, and the test runner

## App Store readiness notes

- Uses public Apple APIs only.
- Does not request location, Wi-Fi SSID, Bluetooth, contacts, photos, or other sensitive permissions.
- Avoids restricted Wi-Fi identifiers so the app can be reviewed as a network-quality tool without special entitlements.
- Includes in-app privacy disclosure and a privacy manifest.
- Uses `ITSAppUsesNonExemptEncryption = false` because the app only uses standard HTTPS networking.

Before App Store Connect submission, add your Apple Developer Team ID in Xcode, create production screenshots, complete App Privacy answers, and provide a hosted privacy policy URL.

## Build and test

Open `TestWifiSpeed.xcodeproj` in Xcode 16.4 or newer, then run the `TestWifiSpeed` scheme on an iOS 17+ simulator or device.

Command-line test example:

```sh
xcodebuild test -scheme TestWifiSpeed -destination 'platform=iOS Simulator,name=iPhone 16'
```
