import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'home_shell.dart';
import 'services/ad_mob_config.dart';
import 'services/app_open_ad_service.dart';
import 'services/interstitial_ad_service.dart';
import 'theme.dart';
import 'widgets/force_update_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AdMobConfig.isSupportedPlatform) {
    await MobileAds.instance.initialize();
    AppOpenAdService.instance.start();
    InterstitialAdService.instance.load();
  }
  runApp(const PdfToolkitApp());
}

class PdfToolkitApp extends StatelessWidget {
  const PdfToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Toolkit',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const ForceUpdateGate(child: HomeShell()),
    );
  }
}
