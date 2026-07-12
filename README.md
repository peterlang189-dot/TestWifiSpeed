# Test WiFi Speed

Test WiFi Speed is a SwiftUI iOS app for measuring network latency, jitter, download speed, and upload speed. The app is designed for App Store submission with public APIs, a privacy manifest, English-first localization, Simplified Chinese support, and light/dark appearance controls.

## Features

- Real HTTPS-based speed test using public endpoints
- Latency, jitter, download, upload, and quality grade
- Local-only recent test history with an in-app clear action
- English by default, with Simplified Chinese available in app settings
- System, light, and dark appearance modes
- First-run and cellular-data disclosures for tests that use about 29 MB
- In-app links to the privacy policy, Cloudflare privacy policy, and support information
- `PrivacyInfo.xcprivacy` declaring no tracking and the data processed by the speed-test provider
- Unit tests for speed calculations, grading, localization defaults, and the test runner

## App Store readiness notes

- Uses public Apple APIs only.
- Does not request location, Wi-Fi SSID, Bluetooth, contacts, photos, or other sensitive permissions.
- Avoids restricted Wi-Fi identifiers so the app can be reviewed as a network-quality tool without special entitlements.
- Includes an in-app disclosure, [privacy policy](PRIVACY.md), [support page](SUPPORT.md), and privacy manifest.
- Speed tests use Cloudflare HTTPS endpoints. Cloudflare receives the connection IP address and derives approximate location and network information as described in the privacy policy.
- Uses `ITSAppUsesNonExemptEncryption = false` because the app only uses standard HTTPS networking.

Before App Store Connect submission, build with Xcode 26 and the iOS 26 SDK or later, create production screenshots, and make the App Privacy answers match `PRIVACY.md` and `PrivacyInfo.xcprivacy`.

## Build and test

Open `TestWifiSpeed.xcodeproj` in Xcode 26 or newer for App Store submission, then run the `TestWifiSpeed` scheme on an iOS 17+ simulator or device.

Command-line test example:

```sh
xcodebuild test -scheme TestWifiSpeed -destination 'platform=iOS Simulator,name=iPhone 16'
```
