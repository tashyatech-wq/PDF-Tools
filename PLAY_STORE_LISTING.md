# PDF Tools — Play Store Listing Content (draft)

Everything below is ready to paste into Play Console. Fill in the two
`[ ... ]` placeholders (support email, privacy policy URL) before submitting.

## App details

- **App name**: PDF Tools
- **Package name**: `in.tashyalabs.pdf_toolkit`
- **Developer**: Tashya Labs Pvt Ltd
- **Category**: Productivity (Tools is a reasonable alternate)
- **Contains ads**: Yes
- **In-app purchases**: No

## Short description (max 80 characters)

```
Scan, merge, split, compress, and unlock PDFs — fast, free, on-device.
```
(71 characters)

## Full description (max 4000 characters)

```
PDF Tools is a fast, no-frills PDF toolkit that handles the PDF jobs you run into every day — without uploading your files anywhere.

FEATURES

📷 Scan to PDF
Turn paper documents, receipts, or whiteboards into a clean PDF using your camera, with automatic edge detection.

🔗 Merge PDF
Combine multiple PDFs into a single file, in the order you choose.

✂️ Split PDF
Pull specific pages out of a PDF, or split a large document into separate files.

🗜️ Compress PDF
Shrink a PDF's file size so it's easier to email or upload, without losing readability.

🔓 Unlock PDF
Remove a known password from a protected PDF so you can open and edit it freely.

YOUR FILES, YOUR PHONE
All PDF processing happens locally on your device. Your files are not uploaded to any server to perform these operations.

SIMPLE, FOCUSED DESIGN
No clutter, no sign-up, no subscription. Open the tool you need, pick your file, done — and every processed file is saved in one place so you can find it again.

PDF Tools is supported by ads to keep the app free for everyone.

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

Pick one — I can set either of these up:
1. **GitHub Pages** (free, uses this repo) — I publish the text above as a
   page at `https://tashyatech-wq.github.io/PDF-Tools/privacy-policy.html`
   and enable Pages on the repo. Takes a few minutes, no cost.
2. **Your own site**, if Tashya Labs already has one — tell me the domain
   and I'll hand you a ready-to-upload HTML file instead.

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
