# App Store Submission Checklist

Last updated: July 12, 2026

## Build

- Install Xcode 26 or later and build with the iOS 26 SDK or later.
- Keep the deployment target at iOS 17 unless product requirements change.
- Create a fresh Release archive after installing Xcode 26; do not upload the existing Xcode 16.4 archive.
- Confirm bundle ID `com.peterlang189.TestWifiSpeed`, version `1.0`, and a unique build number.

## Product page

- Suggested primary category: Utilities.
- Privacy Policy URL: `https://github.com/peterlang189-dot/TestWifiSpeed/blob/main/PRIVACY.md`
- Support URL: `https://github.com/peterlang189-dot/TestWifiSpeed/blob/main/SUPPORT.md`
- Upload at least one current iPhone screenshot. Because the target supports iPad, upload current iPad screenshots too.
- Complete the description, keywords, copyright, age rating, review contact, pricing, and availability fields.

## App Privacy answers

The answers in App Store Connect must remain consistent with `PRIVACY.md` and `PrivacyInfo.xcprivacy`:

- Tracking: No.
- Data used for third-party advertising: No.
- Data linked to the user's identity: No, based on the current account-free implementation and Cloudflare's published speed-test handling.
- Data processed for App Functionality: Coarse Location and Other Data Types (IP/network ASN and network measurements processed by Cloudflare).

Re-check Cloudflare's policy immediately before submission and update these answers if its processing changes.

## Review notes

Suggested review note:

> Test WiFi Speed does not scan for Wi-Fi networks or access SSIDs. It analyzes the active Internet connection using public HTTPS endpoints provided by Cloudflare. Before the first test, the app discloses that a test uses approximately 29 MB and that Cloudflare receives the connection IP address and derives approximate location and ASN information. Cellular tests require an additional confirmation. Test history is stored only on the device and can be cleared in the app. No account, advertising, analytics SDK, or in-app purchase is used.

## Final verification

- Run all unit tests with Xcode 26.
- Run a Release static analysis with Xcode 26.
- Test on at least one physical iPhone and, if iPad support remains enabled, one physical iPad.
- Test Wi-Fi, cellular, offline, cancellation, first-run disclosure, history clearing, English, Simplified Chinese, light mode, dark mode, portrait, and landscape.
- Upload to TestFlight and complete an internal testing pass before App Review submission.

## Regional availability

If distributing in China mainland, complete any applicable ICP filing and App Store Connect compliance information before selecting that storefront.
