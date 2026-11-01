# PDF Tools Remote Update Config

The app checks this public URL on launch:

`https://cdn.jsdelivr.net/gh/tashyatech-wq/PDF-Tools@main/remote-config/pdf-tools-update.json`

To force old versions to update:

1. Set `force_update` to `true`.
2. Raise `ios_min_version` and/or `android_min_version` above the old app's
   version in `flutter-app/pubspec.yaml`.
3. Replace `ios_store_url` with the real App Store URL after App Store Connect
   creates the app listing.
4. Commit and push this file to `main`.

Example: if the published app is `1.0.0` and the new app is `1.0.1`, set the
minimum version to `1.0.1`. Users on `1.0.0` will see the blocking update
screen before they can use the app.
