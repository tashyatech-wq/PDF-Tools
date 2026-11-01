import 'package:flutter/foundation.dart';

class AdMobConfig {
  const AdMobConfig._();

  static const androidAppId = 'ca-app-pub-7630945652842088~9358322053';

  static const _androidProductionBannerAdUnitId =
      'ca-app-pub-7630945652842088/7555827787';
  static const _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const _androidProductionInterstitialAdUnitId =
      'ca-app-pub-7630945652842088/8930946641';
  static const _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String? get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode
          ? _androidProductionBannerAdUnitId
          : _androidTestBannerAdUnitId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return null;
    }
    return null;
  }

  static String? get interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode
          ? _androidProductionInterstitialAdUnitId
          : _androidTestInterstitialAdUnitId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return null;
    }
    return null;
  }
}
