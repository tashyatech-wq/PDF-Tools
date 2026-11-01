# PDF Tools - Google Play Release Checklist

Last updated: 2026-11-01

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

- [ ] Create/configure a production Android upload keystore
- [ ] Replace debug signing in `android/app/build.gradle.kts` with release signing
- [ ] Build a production-signed Android App Bundle (`.aab`)
- [ ] Verify target SDK meets current Google Play requirement
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

- Release signing is not production-ready. The project currently signs Android release builds with the debug key.
- No upload keystore or `key.properties` exists in the Android project.
- No Play Console service account / Fastlane / Play upload automation is configured in the repo.
- I cannot upload to Play Store directly without Play Console access or a configured service account JSON with release permissions.

## Latest Local Build

- Command verified: `./gradlew :app:bundleRelease --info --stacktrace`
- Result: build successful
- Generated bundle: `flutter-app/build/app/outputs/bundle/release/app-release.aab`
- Size: 57 MB
- Important: this bundle is release-mode but debug-signed, so it should not be uploaded as the production Play Store artifact.

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
