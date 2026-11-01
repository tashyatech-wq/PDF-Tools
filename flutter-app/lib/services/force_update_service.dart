import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class ForceUpdateDecision {
  const ForceUpdateDecision({
    required this.requiresUpdate,
    required this.currentVersion,
    required this.minimumVersion,
    required this.message,
    required this.storeUrl,
  });

  final bool requiresUpdate;
  final String currentVersion;
  final String minimumVersion;
  final String message;
  final Uri? storeUrl;
}

class ForceUpdateService {
  ForceUpdateService._();

  static const configUrl =
      'https://cdn.jsdelivr.net/gh/tashyatech-wq/PDF-Tools@main/remote-config/pdf-tools-update.json';

  static Future<ForceUpdateDecision> check() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      final response = await http
          .get(Uri.parse(configUrl))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _allow(currentVersion);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final platform = _platformKey;
      final minimumVersion =
          (json['${platform}_min_version'] as String?)?.trim() ?? '';
      final forceUpdate = json['force_update'] == true;
      final message = (json['message'] as String?)?.trim().isNotEmpty == true
          ? (json['message'] as String).trim()
          : 'Please update PDF Tools to continue.';
      final storeUrl = Uri.tryParse(
        ((json['${platform}_store_url'] ?? json['store_url']) as String? ?? '')
            .trim(),
      );

      final requiresUpdate =
          forceUpdate &&
          minimumVersion.isNotEmpty &&
          _compareVersions(currentVersion, minimumVersion) < 0;

      return ForceUpdateDecision(
        requiresUpdate: requiresUpdate,
        currentVersion: currentVersion,
        minimumVersion: minimumVersion,
        message: message,
        storeUrl: storeUrl?.hasScheme == true ? storeUrl : null,
      );
    } catch (_) {
      return _allow(currentVersion);
    }
  }

  static ForceUpdateDecision _allow(String currentVersion) =>
      ForceUpdateDecision(
        requiresUpdate: false,
        currentVersion: currentVersion,
        minimumVersion: currentVersion,
        message: '',
        storeUrl: null,
      );

  static String get _platformKey {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'other';
  }

  static int _compareVersions(String current, String minimum) {
    final currentParts = _versionParts(current);
    final minimumParts = _versionParts(minimum);
    final maxLength = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (var i = 0; i < maxLength; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minimumPart = i < minimumParts.length ? minimumParts[i] : 0;
      if (currentPart != minimumPart) {
        return currentPart.compareTo(minimumPart);
      }
    }
    return 0;
  }

  static List<int> _versionParts(String version) {
    final plainVersion = version.split('+').first;
    return plainVersion
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')))
        .map((part) => part ?? 0)
        .toList();
  }
}
