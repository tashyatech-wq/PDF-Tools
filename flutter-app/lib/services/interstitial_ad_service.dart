import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_mob_config.dart';

class InterstitialAdService {
  InterstitialAdService._();

  static final instance = InterstitialAdService._();

  InterstitialAd? _ad;
  bool _isLoading = false;
  DateTime? _lastShownAt;

  void load() {
    if (!AdMobConfig.isSupportedPlatform || _isLoading || _ad != null) return;
    final adUnitId = AdMobConfig.interstitialAdUnitId;
    if (adUnitId == null) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _ad = ad;
          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              load();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _ad = null;
              load();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
        },
      ),
    );
  }

  void showAfterExport() {
    if (!AdMobConfig.isSupportedPlatform) return;

    final now = DateTime.now();
    final lastShownAt = _lastShownAt;
    if (lastShownAt != null &&
        now.difference(lastShownAt) < const Duration(seconds: 90)) {
      return;
    }

    final ad = _ad;
    if (ad == null) {
      load();
      return;
    }

    _lastShownAt = now;
    _ad = null;
    ad.show();
  }
}
