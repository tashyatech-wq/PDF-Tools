# PDF Tools — project notes

Status as of 2026-10-31: web prototype built and iterated; Flutter app scaffold in progress.

## What this app is

An on-device PDF utility app: merge, split, compress, and (eventually) remove a
password — for Android and iOS from one Flutter codebase. The wedge is Indian
government/exam portals that cap file sizes (photo/PDF under a fixed KB limit),
a real, recurring, searched-for need that's currently served by small,
ad-heavy, often upload-to-server competitors (Snapix, ResizeHub, FilePrep,
ExamMint Resizer).

## Architecture decisions

- **Everything runs on-device.** No server, no file upload, no per-file cost.
  This is the core pitch and the main differentiator against incumbents that
  upload documents to process them.
- **One Flutter codebase** for Android + iOS.
- **PDF engine: Syncfusion Flutter PDF** (`syncfusion_flutter_pdf`). It's the
  one library in the Flutter ecosystem with real support for merge, split,
  compress, *and* actual decryption (RC4/AES) — the last one pdf-lib (used in
  the web prototype) cannot do.
  - **Licensing:** qualifies for Syncfusion's free **Community License**
    (under $1M annual revenue, under 5 developers). Needs a one-time
    registration at syncfusion.com for a license key before shipping — not a
    cash cost, just a signup step.
- **Force-update mechanism:** Firebase Remote Config (free Spark tier) —
  compare installed version against a `minimum_supported_version` key on
  launch; block the app with a non-dismissible update dialog if below it.
  Needs a Firebase project created in the user's own Google account — not
  something done from this environment without their login.
- **Monetization:** AdMob (banner + interstitial between operations) + one
  small one-time IAP ("remove ads / batch mode", ₹29–49). No subscription —
  market data says small, frequent purchases convert better than annual
  passes for this kind of task-driven, low-trust-at-first user.

## Tool scope (in build order)

1. **Merge** — fully working in the web prototype (pdf-lib).
2. **Split** — page range extraction + "split every page" (zipped). Fully
   working in the web prototype.
3. **Compress** — re-packs/strips metadata. Fully working, but honestly
   scoped: on-device compression won't match a Ghostscript server on heavily
   image-based PDFs. Good enough for "get this under a portal's size cap,"
   not a general-purpose compressor.
4. **Unlock (remove password)** — NOT implemented in the web prototype.
   pdf-lib can't decrypt real PDF encryption; this needs the Flutter build's
   Syncfusion engine, which genuinely supports it. This is the one feature
   to build and test against real protected files before shipping.

## Web prototype

Live file: `web-prototype/pdf-toolkit.html` — a single self-contained HTML
file (pdf-lib + JSZip from CDN, no build step) that doubles as:
- A working demo of the architecture (open it, drop in a real PDF, watch it
  process with no network activity).
- The free browser-tool version for tashyalabs.in's Tools section, which
  doubles as a zero-cost way to validate demand (traffic/analytics) before
  fully committing to the Play Store build.

It's also published as a Claude Artifact for live demoing — ask Claude for
the current link if it's not at hand; Artifact publishes always deploy from
Claude's own working/scratchpad directory, never directly from this external
folder, so this file here is the canonical copy and gets kept in sync
whenever the artifact is updated.

Design: phone-shaped app shell (not a webpage layout) — top app bar, bottom
tab bar, one signature accent color per tool (merge=blue, split=purple,
compress=teal, unlock=amber), matching Tashya Labs' brand palette.

## Revenue context (see full chat analysis for sources/methodology)

Realistic range for a new, unbranded entrant: low lakhs in year 1, potentially
₹20–50L/year by year 2–3 with strong execution and ASO — not a breakout
product, but a real, low-infrastructure-cost way to get a first app earning.
Comparable small PDF/photo utility apps (Flippa sale listings) show
$800–2,900/month profit as an achievable band for a well-executed niche tool.

## Flutter app status (as of 2026-11-01)

Scaffolded and working at `flutter-app/`:

- `lib/theme.dart` — brand palette + per-tool accent colors, `ToolAccent`
  wrapper (same trick as the web prototype's CSS `--accent` token).
- `lib/services/pdf_service.dart` — merge, split (range + every-page),
  compress, and **remove password** (genuinely implemented — Syncfusion
  really decrypts, unlike pdf-lib in the web version). Every API used here
  was verified against the actual `syncfusion_flutter_pdf-35.1.42` package
  source in pub cache, not written from memory.
- `lib/services/save_file.dart` — writes output to a temp file and opens the
  native share sheet (the mobile equivalent of the web version's download).
- `lib/screens/*.dart` — the four tool screens.
- `lib/home_shell.dart` — app bar + bottom nav shell matching the web
  prototype's design.

**Verified:** `flutter analyze` is clean, the widget test passes, and the
app genuinely builds and launches on macOS desktop (confirmed via a real
`flutter run -d macos` — the Dart VM started and `pdf_toolkit.app` exists on
disk). The GUI window couldn't be brought to the foreground in this
sandboxed, headless dev environment (no display session), so no actual
click-through / visual QA of the running app has happened yet — that still
needs to happen on a real machine or simulator.

**Not yet possible from this environment:**
- Android build — needs Android Studio + the Android SDK (not installed).
- iOS build — needs a full Xcode install, not just the command-line tools
  (only CLT is present; `flutter doctor` flags Xcode as incomplete).
- Click-through UI verification — needs a real display, i.e. this needs to
  run on your actual Mac session, a simulator, or a physical device.

## Next steps

- [x] Finish Flutter SDK install + `flutter create` scaffold
- [x] Add `syncfusion_flutter_pdf` dependency, implement the 4 screens
- [ ] Install Android Studio (Android SDK) and/or full Xcode to actually
      build and click through the app on a device/simulator
- [ ] Register Syncfusion Community License key
- [ ] Set up Firebase project for force-update config
- [ ] Register Tashya Labs as a Play Console **organization** account
      (exempts every future app from the 12-tester/14-day closed-testing
      requirement that applies to personal accounts)
- [ ] Ship the web-tool versions on tashyalabs.in first to validate demand
      before/alongside the Play Store submission
