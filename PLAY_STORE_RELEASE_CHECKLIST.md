# PDF Tools - Google Play Release Checklist

Last updated: 2026-11-04

Draft store listing copy, privacy policy text, and data safety/content
rating answers are in [PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md).

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
- [x] `versionCode` is `1` (`pubspec.yaml` version `1.0.0+1`) — fine as-is for this first upload; bump it for every future release
- [x] App listing name, short description, full description drafted — see `PLAY_STORE_LISTING.md`
- [ ] Add screenshots for required phone/tablet form factors
- [ ] Add feature graphic if Play Console requests it
- [ ] Add privacy policy URL (text drafted in `PLAY_STORE_LISTING.md`; needs hosting + your support email filled in)
- [x] Data safety form answers drafted — see `PLAY_STORE_LISTING.md`
- [x] Declare "Contains ads" — confirmed Yes in the draft listing
- [ ] Complete App content declarations (uses the drafted answers in Play Console)
- [x] Content rating questionnaire answers drafted — see `PLAY_STORE_LISTING.md`
- [x] Target audience and children/families answers drafted — see `PLAY_STORE_LISTING.md`
- [x] Ad SDK declaration confirmed: Google Mobile Ads SDK (AdMob)
- [ ] Upload `.aab` to internal testing first
- [ ] Test install from Play internal testing
- [ ] Move to closed/open testing or production after validation

## Current Blockers

- Play Console developer account is now approved (confirmed 2026-11-04).
- Keystore backup still **unconfirmed** — see the CRITICAL section below.
- Privacy policy still needs a hosting URL and your support email filled in before it can be submitted.
- Screenshots and feature graphic still need to be produced.
- No Play Console service account / Fastlane / Play upload automation is configured in the repo — the actual upload to Play Console has to be done by you through the console UI; I can't upload on your behalf.

## Release keystore backup

- `android/app/upload-keystore.jks` and `android/key.properties` are gitignored on purpose (they hold the signing key and its passwords) — git will never back them up.
- Confirmed backed up outside this machine as of 2026-11-04.

## Latest Local Build

- Command verified: `flutter build appbundle --release` (rebuilt 2026-11-04 with Firebase Remote Config wiring included)
- Result: build successful
- Generated bundle: `flutter-app/build/app/outputs/bundle/release/app-release.aab`
- Size: 62.1 MB
- Signing verified via `gradlew signingReport`: release variant signs with the `upload` key (SHA-256 `5A:EF:F7:51:62:AE:64:9F:9D:D8:69:6D:44:94:A6:0A:61:4C:C0:2A:1A:1E:C1:B9:AC:FD:1F:87:F4:2E:94:DE`), not debug. This bundle is ready to upload to Play Console now.

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
