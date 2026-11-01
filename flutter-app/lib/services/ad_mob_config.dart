import 'package:flutter/foundation.dart';

class AdMobConfig {
  const AdMobConfig._();

  static const androidAppId = 'ca-app-pub-7630945652842088~9358322053';
  static const iosAppId = 'ca-app-pub-7630945652842088~3050119918';

  static const _androidProductionBannerAdUnitId =
      'ca-app-pub-7630945652842088/7555827787';
  static const _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const _iosProductionBannerAdUnitId =
      'ca-app-pub-7630945652842088/4220178460';
  static const _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2435281174';
  static const _androidProductionInterstitialAdUnitId =
      'ca-app-pub-7630945652842088/8930946641';
  static const _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _androidProductionToolNativeAdUnitId =
      'ca-app-pub-7630945652842088/4269821911';
  static const _androidProductionSavedFilesNativeAdUnitId =
      'ca-app-pub-7630945652842088/1643658572';
  static const _androidTestNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const _androidProductionAppOpenAdUnitId =
      'ca-app-pub-7630945652842088/4443092638';
  static const _androidTestAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const _iosProductionInterstitialAdUnitId =
      'ca-app-pub-7630945652842088/5017807700';
  static const _iosTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const _iosProductionToolNativeAdUnitId =
      'ca-app-pub-7630945652842088/6213458972';
  static const _iosProductionSavedFilesNativeAdUnitId =
      'ca-app-pub-7630945652842088/8592210304';
  static const _iosTestNativeAdUnitId =
      'ca-app-pub-3940256099942544/3986624511';
  static const _iosProductionAppOpenAdUnitId =
      'ca-app-pub-7630945652842088/2834497492';
  static const _iosTestAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/5575463023';
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
      return kReleaseMode
          ? _iosProductionBannerAdUnitId
          : _iosTestBannerAdUnitId;
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
      return kReleaseMode
          ? _iosProductionInterstitialAdUnitId
          : _iosTestInterstitialAdUnitId;
    }
    return null;
  }

  static String? get toolNativeAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode
          ? _androidProductionToolNativeAdUnitId
          : _androidTestNativeAdUnitId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return kReleaseMode
          ? _iosProductionToolNativeAdUnitId
          : _iosTestNativeAdUnitId;
    }
    return null;
  }

  static String? get savedFilesNativeAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode
          ? _androidProductionSavedFilesNativeAdUnitId
          : _androidTestNativeAdUnitId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return kReleaseMode
          ? _iosProductionSavedFilesNativeAdUnitId
          : _iosTestNativeAdUnitId;
    }
    return null;
  }

  static String? get appOpenAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode
          ? _androidProductionAppOpenAdUnitId
          : _androidTestAppOpenAdUnitId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return kReleaseMode
          ? _iosProductionAppOpenAdUnitId
          : _iosTestAppOpenAdUnitId;
    }
    return null;
  }
}
