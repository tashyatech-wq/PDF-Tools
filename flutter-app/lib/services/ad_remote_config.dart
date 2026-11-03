import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Per-placement kill switches so each ad type can be turned on from the
/// Firebase console once the install base is big enough, without shipping
/// an app update. Every flag defaults to off, so the app stays ad-free if
/// Firebase isn't configured yet, there's no network, or the console flag
/// was never set.
class AdRemoteConfig {
  AdRemoteConfig._();

  static const _keyBanner = 'show_banner_ads';
  static const _keyInterstitial = 'show_interstitial_ads';
  static const _keyNative = 'show_native_ads';
  static const _keyAppOpen = 'show_app_open_ads';

  static bool _bannerAds = false;
  static bool _interstitialAds = false;
  static bool _nativeAds = false;
  static bool _appOpenAds = false;

  static bool get bannerAdsEnabled => _bannerAds;
  static bool get interstitialAdsEnabled => _interstitialAds;
  static bool get nativeAdsEnabled => _nativeAds;
  static bool get appOpenAdsEnabled => _appOpenAds;

  /// Fetches the flags once at startup. Any failure (Firebase not set up,
  /// no network, console not configured) is swallowed and simply leaves
  /// every placement at its off-by-default value.
  static Future<void> init() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults(const {
        _keyBanner: false,
        _keyInterstitial: false,
        _keyNative: false,
        _keyAppOpen: false,
      });
      await remoteConfig.fetchAndActivate();
      _bannerAds = remoteConfig.getBool(_keyBanner);
      _interstitialAds = remoteConfig.getBool(_keyInterstitial);
      _nativeAds = remoteConfig.getBool(_keyNative);
      _appOpenAds = remoteConfig.getBool(_keyAppOpen);
    } catch (_) {
      // Keep the all-off defaults.
    }
  }
}
