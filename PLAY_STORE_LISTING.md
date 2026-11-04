# PDF Tools — Play Store Listing Content (draft)

Everything below is ready to paste into Play Console.

## Competitive positioning (ASO notes)

Researched the live iLovePDF Play Store listing (`com.ilovepdf.www`) directly
to ground this, not guessing:

- **iLovePDF**: title `iLovePDF: PDF Editor & Scanner`, 10M+ downloads, 4.6★
  from 355K reviews, Productivity category, has in-app purchases (auto-renewing
  Premium subscription), collects Personal info + App activity + App info and
  performance per their own Data safety section, ~15 tools (scanner, OCR,
  converters, annotate, fill & sign, compress, merge, split, rotate,
  protect, page numbers, watermark).
- Their own short description line is literally **"PDF Tools. Sign, edit
  and convert PDF"** — confirms "PDF Tools" is an unprotectable generic
  term, not a trademark conflict for us.
- **Reality check**: with 10M+ installs and 355K reviews, iLovePDF will
  outrank us on any single generic keyword ("pdf editor", "pdf converter")
  for a long time — that's an install-velocity and review-count problem,
  not something listing copy alone fixes. ASO copy can only point search
  traffic that's already using long-tail/specific-tool queries at us; it
  can't win head-to-head on broad terms against an incumbent this size.
- **Our real, honest differentiators** (don't name iLovePDF directly in
  Play Store copy — Google's metadata policy disallows referencing
  competitors by name in your own listing):
  - Fully free, no subscription, no in-app purchases at all (one live
    iLovePDF review in this research literally complains about confusing
    subscription billing — "no subscription" is a genuine selling point).
  - No account/sign-up required.
  - All processing happens on-device — nothing uploaded, which iLovePDF's
    own Data safety disclosure (collects Personal info + App activity)
    doesn't match.
  - Smaller, more focused tool set — faster to find the one thing you need.
- **Keyword strategy**: pack the 30-char title with 2–3 high-intent tool
  keywords so we rank for specific-tool searches (merge/split/scan) rather
  than competing on saturated generic terms; use the short description for
  *different* keywords (compress, unlock, offline, free, no sign-up) so the
  combined title+short-description keyword coverage doesn't repeat itself.

## App details

- **App name (Play Store listing title, max 30 characters)**:
  ```
  PDF Tools: Merge, Split & Scan
  ```
  (30 characters, exact fit — the app's home-screen label stays the
  shorter "PDF Tools"; Play Console's "App name" field is the one that
  carries this longer keyword-rich version and is normal, policy-allowed
  practice.)
- **Package name**: `in.tashyalabs.pdf_toolkit`
- **Developer**: Tashya Labs Pvt Ltd
- **Category**: Productivity (matches iLovePDF's category — that's where
  this search traffic actually browses)
- **Contains ads**: Yes
- **In-app purchases**: No

## Short description (max 80 characters)

```
Compress, unlock & organize PDFs offline. Free, no sign-up, no subscription.
```
(76 characters — deliberately covers different keywords than the title:
compress/unlock/offline/free/no sign-up/no subscription, so title + short
description together cover more unique search terms instead of repeating
"merge/split/scan" twice.)

## Full description (max 4000 characters)

```
PDF Tools is a fast, no-frills PDF toolkit for the PDF jobs you run into every day — scan, merge, split, compress, and unlock PDF files, all without uploading anything to a server.

100% FREE. NO SIGN-UP. NO SUBSCRIPTION.
No account, no premium paywall, no recurring billing — install it and use every tool, free.

FEATURES

📷 Scan to PDF — PDF Scanner
Turn paper documents, receipts, notes, or whiteboards into a clean PDF using your camera. Automatic edge detection turns any photo into a properly cropped page.

🔗 Merge PDF — Combine PDF Files
Use the PDF merger to combine multiple PDFs into a single file, in the order you choose. Perfect for putting scanned pages or separate reports together.

✂️ Split PDF — Extract PDF Pages
Pull specific pages out of a PDF with the PDF splitter, or break a large document into separate files.

🗜️ Compress PDF — Reduce PDF File Size
Shrink a PDF's file size with the PDF compressor so it's easier to email or upload, without losing readability.

🔓 Unlock PDF — Remove PDF Password
Use the PDF password remover to take a known password off a protected PDF so you can open, edit, or share it freely.

YOUR FILES NEVER LEAVE YOUR PHONE
Every PDF operation above — scanning, merging, splitting, compressing, unlocking — runs entirely on your device. Nothing is uploaded to any server to do the work.

SIMPLE, FOCUSED DESIGN
No clutter, no clunky menus. Open the tool you need, pick your file, done — and every processed file is saved in one place (the Saved tab) so you can find it again later.

PDF Tools is supported by ads to stay free for everyone, with no subscription and no in-app purchases.

Questions or feedback? Reach us at tashya.tech@gmail.com.
```

## Privacy policy

Required because the app shows ads (Google AdMob, which uses the advertising
ID) and requests camera access for the Scan tool. Host the text below at a
public URL (see "Hosting the privacy policy" below) and put that URL in
Play Console → Policy → App content → Privacy policy.

```
Privacy Policy for PDF Tools

Last updated: November 4, 2026

Tashya Labs Pvt Ltd ("we", "us") operates the PDF Tools mobile application
(the "App"). This policy explains what information the App collects and how
it is used.

1. PDF processing
All PDF operations performed by the App (merge, split, compress, unlock,
and scan-to-PDF) happen locally on your device. The files you select are
not uploaded to our servers or any third party to perform these operations.

2. Camera
The App requests camera access only for the Scan tool, which lets you
capture a paper document and convert it to a PDF. Camera access is used
solely for this purpose and is requested only when you use that tool.

3. Advertising
The App displays ads served through Google AdMob (Google Mobile Ads SDK).
Google AdMob may collect and use the advertising identifier and related
diagnostic data to serve and measure ads. You can review how Google
handles this data, and manage your ad personalization settings, at
https://policies.google.com/technologies/ads.

4. Data we do not collect
We do not require account creation, and we do not collect your name,
email address, or the contents of your files on our own servers.

5. Children's privacy
The App is not directed at children under 13, and we do not knowingly
collect personal information from children.

6. Changes to this policy
We may update this policy from time to time. Changes will be posted at
this same URL with an updated "Last updated" date.

7. Contact
Questions about this policy can be sent to tashya.tech@gmail.com.
```

### Hosting the privacy policy

Live at **https://tashyatech-wq.github.io/PDF-Tools/privacy-policy.html**
via GitHub Pages (served from `docs/privacy-policy.html` on `main`, free).
Paste that URL into Play Console → Policy → App content → Privacy policy.

## Data safety form answers (Play Console → App content → Data safety)

- **Does your app collect or share any of the required user data types?**
  Yes (because of the ads SDK).
- **Data types collected**:
  - *Device or other IDs* → Advertising ID — collected, used for
    Advertising or marketing, shared with Google (AdMob). Not required to
    be collected (ads still serve without it if the user opts out via OS
    settings, so mark "optional"/"not required" per the actual SDK
    behavior you ship).
  - Nothing else is collected — no name, email, location, contacts,
    photos/files, or financial info leave the device.
- **Is data encrypted in transit?** Yes (handled by AdMob SDK itself).
- **Can users request data deletion?** Not applicable — the app does not
  collect personal data tied to an account (no account exists).

## Content rating questionnaire

- Violence / sexual content / profanity / drugs: None — answer "No" to all.
- User-generated content: No.
- Shares location: No.
- Digital purchases: No.
- Expected outcome: rating around "Everyone" / "PEGI 3", since the app has
  no mature content — ads may still nudge the rating slightly depending on
  ad network content, which is normal and expected for any ad-supported
  app.

## Target audience and children's settings

- Target age group: 18 and over is the safest choice given this app is a
  general productivity utility monetized with ads (Play's Families
  Policy adds real restrictions — like limits on ad SDKs — if you target
  under-13 audiences, which this app isn't built for).
- "Is your app directed at children?" → No.

## Ad SDK declarations

- Declare **Google Mobile Ads SDK** (AdMob) under App content → Ads →
  "Does your app contain ads?" → Yes.
- You'll also be asked to confirm the app follows Google Play's ads
  policy (no accidental clicks, no ads that mimic system UI) — nothing
  in this app's ad placements (banner, interstitial, native, app-open)
  violates that as implemented.
