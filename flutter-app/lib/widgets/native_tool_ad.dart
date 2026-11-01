import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_mob_config.dart';

class NativeToolAd extends StatelessWidget {
  const NativeToolAd({super.key});

  @override
  Widget build(BuildContext context) {
    return _NativeTemplateAd(
      adUnitId: AdMobConfig.toolNativeAdUnitId,
      margin: const EdgeInsets.only(top: 14),
    );
  }
}

class NativeSavedFilesAd extends StatelessWidget {
  const NativeSavedFilesAd({super.key});

  @override
  Widget build(BuildContext context) {
    return _NativeTemplateAd(adUnitId: AdMobConfig.savedFilesNativeAdUnitId);
  }
}

class _NativeTemplateAd extends StatefulWidget {
  const _NativeTemplateAd({
    required this.adUnitId,
    this.margin = EdgeInsets.zero,
  });

  final String? adUnitId;
  final EdgeInsetsGeometry margin;

  @override
  State<_NativeTemplateAd> createState() => _NativeTemplateAdState();
}

class _NativeTemplateAdState extends State<_NativeTemplateAd> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nativeAd != null) return;

    final adUnitId = widget.adUnitId;
    if (!AdMobConfig.isSupportedPlatform || adUnitId == null) return;

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _nativeAd = null;
            _isLoaded = false;
          });
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
        cornerRadius: 14,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: scheme.primary,
          size: 13,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white : const Color(0xFF171717),
          size: 13,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF525252),
          size: 11,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? const Color(0xFFA3A3A3) : const Color(0xFF737373),
          size: 10,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nativeAd = _nativeAd;
    if (!_isLoaded || nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 96,
      margin: widget.margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: AdWidget(ad: nativeAd),
    );
  }
}
