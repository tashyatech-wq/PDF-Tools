# PDF Tools - Google Play Release Checklist

Last updated: 2026-11-03

## Current App Status

- [x] Android package id set: `in.tashyalabs.pdf_toolkit`
- [x] App name set: `PDF Tools`
- [x] Android launcher icon resources present
- [x] Release Android App Bundle build completes locally
- [x] Android AdMob app id added in `AndroidManifest.xml`
- [x] Android banner ad unit wired
- [x] Android task-complete interstitial ad unit wired
- [x] Android tool-screen native ad unit wired
- [x] Android saved-files native ad unit wired
- [x] Android app-open ad unit wired
- [x] iOS AdMob ids also wired for matching placements
- [x] Flutter analysis passes

## Must Complete Before Play Store Upload

- [x] Create/configure a production Android upload keystore (`android/app/upload-keystore.jks`, gitignored; alias `upload`, valid until 2054)
- [x] Replace debug signing in `android/app/build.gradle.kts` with release signing (reads `android/key.properties`, gitignored, falls back to debug only when that file is absent)
- [x] Build a production-signed Android App Bundle (`.aab`) — verified via `gradlew signingReport`, release variant now uses the `upload` key, not debug
- [x] Verify target SDK meets current Google Play requirement (compileSdk/targetSdk 36, minSdk 24 — comfortably above Play's current minimum)
- [ ] Increase `versionCode` for each future upload
- [ ] Confirm app listing name, short description, full description
- [ ] Add screenshots for required phone/tablet form factors
- [ ] Add feature graphic if Play Console requests it
- [ ] Add privacy policy URL
- [ ] Complete Data safety form
- [ ] Declare "Contains ads"
- [ ] Complete App content declarations
- [ ] Confirm content rating questionnaire
- [ ] Confirm target audience and children/families answers
- [ ] Confirm ad SDK declarations and Google Mobile Ads usage
- [ ] Upload `.aab` to internal testing first
- [ ] Test install from Play internal testing
- [ ] Move to closed/open testing or production after validation

## Current Blockers

- Play Console developer account is not yet approved, so nothing can actually be uploaded yet.
- No Play Console service account / Fastlane / Play upload automation is configured in the repo.
- I cannot upload to Play Store directly without Play Console access or a configured service account JSON with release permissions.
- Camera is a hard device requirement in Play's eyes until `<uses-feature android:name="android.hardware.camera" android:required="false"/>` is added to `AndroidManifest.xml` (only the Scan tool needs a camera; the rest of the app doesn't).

## CRITICAL: Back up the release keystore now

- `android/app/upload-keystore.jks` and `android/key.properties` are gitignored on purpose (they hold the signing key and its passwords) — which also means **git will never back them up**.
- If this keystore is lost, this app can never be updated again under this listing once it's published (a new listing would be a different app with zero reviews/installs carried over).
- Copy both files somewhere durable and private right now: a password manager's file attachment, an encrypted drive, or a secure cloud folder — not just this machine.

## Latest Local Build

- Command verified: `flutter build appbundle --release`
- Result: build successful
- Generated bundle: `flutter-app/build/app/outputs/bundle/release/app-release.aab`
- Size: 61.6 MB
- Signing verified via `gradlew signingReport`: release variant signs with the `upload` key (SHA-256 `5A:EF:F7:51:62:AE:64:9F:9D:D8:69:6D:44:94:A6:0A:61:4C:C0:2A:1A:1E:C1:B9:AC:FD:1F:87:F4:2E:94:DE`), not debug. This bundle is safe to upload once the Play Console account is approved.

## Recommended Release Track

1. Configure release signing.
2. Build a signed `.aab`.
3. Upload to Play Console internal testing.
4. Fill store listing and policy forms.
5. Test the Play-installed build on real Android devices.
6. Promote to production after ads, PDF tools, saved files, and force-update behavior are verified.

## Notes For Data Safety

- The app processes PDF files locally.
- The app displays ads through Google Mobile Ads SDK.
- The Play Console Data safety form should account for ad SDK behavior, including advertising identifiers and ad-related diagnostics if applicable.
- If the app has a privacy policy screen/link, keep it consistent with the Play Console Data safety answers.
