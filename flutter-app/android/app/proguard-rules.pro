# Google ML Kit / Play Services document scanner (used directly by
# google_mlkit_document_scanner, and internally by cunning_document_scanner's
# Android fallback). Without these, R8 strips internal wiring the scanner
# needs at runtime, throwing a NullPointerException the instant it starts
# and silently dropping every scan to the manual, non-auto-detecting
# fallback cropper in release builds only (debug is unminified, so it never
# shows up there).
#
# Narrow keep rules scoped to just the document-scanner package were NOT
# enough: the actual throw site is `Field.getType()` on a null Field deep in
# a *shared* Play Services reflection/module-loading utility outside that
# package, so the whole client library needs to be kept intact.
-keep class com.google.android.gms.** { *; }
-keep class com.google.mlkit.** { *; }

# Play Services' SafeParcelable wire format is read via the Parcelable
# CREATOR field through reflection; keep it so (de)serialization across the
# service boundary survives minification.
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# The two scanner plugins' own classes.
-keep class biz.cunning.cunning_document_scanner.** { *; }
-keep class com.google_mlkit_document_scanner.** { *; }

-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
