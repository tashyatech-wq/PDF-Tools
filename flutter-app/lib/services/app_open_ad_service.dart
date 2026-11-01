import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_mob_config.dart';

class AppOpenAdService with WidgetsBindingObserver {
  AppOpenAdService._();

  static final instance = AppOpenAdService._();

  static const _maxAdAge = Duration(hours: 4);
  static const _minShowInterval = Duration(minutes: 15);

  AppOpenAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _started = false;
  bool _wasBackgrounded = false;
  DateTime? _loadedAt;
  DateTime? _lastShownAt;

  void start() {
    if (_started || !AdMobConfig.isSupportedPlatform) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  void load() {
    final adUnitId = AdMobConfig.appOpenAdUnitId;
    if (adUnitId == null || _isLoading || _ad != null) return;

    _isLoading = true;
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loadedAt = null;
          _isLoading = false;
        },
      ),
    );
  }

  void showIfAvailable() {
    final ad = _ad;
    if (_isShowing || ad == null) {
      load();
      return;
    }

    final now = DateTime.now();
    final loadedAt = _loadedAt;
    if (loadedAt == null || now.difference(loadedAt) > _maxAdAge) {
      ad.dispose();
      _ad = null;
      _loadedAt = null;
      load();
      return;
    }

    final lastShownAt = _lastShownAt;
    if (lastShownAt != null && now.difference(lastShownAt) < _minShowInterval) {
      return;
    }

    _isShowing = true;
    _lastShownAt = now;
    _ad = null;
    _loadedAt = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        load();
      },
    );
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _wasBackgrounded = true;
      return;
    }

    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      showIfAvailable();
    }
  }
}
