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
- [x] Screenshots captured from a real signed-release install — see `store-assets/screenshots/phone/`
- [x] App icon (512x512) ready for Play Console's Main store listing → App icon field — see `store-assets/icon/play-store-icon-512.png`
- [x] Feature graphic (1024x500) generated from the app's icon and brand colors — see `store-assets/feature-graphic/feature-graphic-1024x500.png`
- [x] Verified end-to-end: Internal testing opt-in link → install → launch works (confirmed via `installerPackageName=com.android.vending`, genuine Play Store install, not sideload). The generic robot icon and "(unreviewed)" app name shown to testers right now is expected Play behavior until the store listing (name, icon, etc.) is completed — not a bug.
- [x] Privacy policy live at https://tashyatech-wq.github.io/PDF-Tools/privacy-policy.html (GitHub Pages, served from `docs/`)
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
- Feature graphic still needs to be produced (4 phone screenshots already captured — see `store-assets/screenshots/phone/`).
- Developer-account-level fields (legal name/address, contact info, payment methods, package name registration under Android Developer Verification) still need to be confirmed/completed by you directly in Play Console — see "Play Console Requirements compliance" below.
- No Play Console service account / Fastlane / Play upload automation is configured in the repo — the actual upload to Play Console has to be done by you through the console UI; I can't upload on your behalf.

## Play Console Requirements compliance (reviewed 2026-11-04)

Checked against https://support.google.com/googleplay/android-developer/answer/10788890 —
- [x] App has no login/account system at all (confirmed in code) — answer "No" to "does your app require a login", no demo account needed.
- [x] Not a financial/health/VPN/government app — a Personal developer account is fine, Organization registration not required.
- [x] Only third-party SDKs are Google Mobile Ads (disclosed in Data safety) and Firebase Core/Remote Config (app config only, not user data collection — no separate Data safety entry needed).
- [ ] Still needs to be done by you in Play Console itself (account-level — legal name/address, financial/identity info, not something I can touch): confirm developer account legal name/address, contact email/phone, payment methods, and Google payment profile are accurate, and register the app's package name under Android Developer Verification.
- Not applicable: the Account Transfer section of that same policy page — you're not transferring the account.

### Android Developer Verification (https://developer.android.com/developer-verification)

- Separate, newer program (enforcement starts 2026-09-30 for Brazil/Indonesia/Singapore/Thailand on certified Android 7+ devices, global rollout 2027) requiring a verified real-world identity behind every installable app.
- **Confirmed from Google's own FAQ: this is automatic for us.** "If you use Play App Signing, we have the necessary information to securely identify your ownership. Your eligible apps will be part of the automatic registration process." Play App Signing is the default/required signing path for App Bundle (`.aab`) uploads, which is exactly what we're uploading — so no extra registration step for an app distributed only through Google Play.
- One thing to check yourself after the first upload: Play Console → Setup → **Android developer verification** page shows this app's registration status directly (should read "Registered" once Play App Signing is confirmed during upload).
- Not relevant to us: the separate Android Developer Console / package-name-registration flow — that's only for apps distributed *outside* Google Play (sideloading, other stores), which this app isn't.

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
