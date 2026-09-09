import 'package:flutter/services.dart';

class AppInfo {
  const AppInfo({required this.packageName, required this.appName});
  final String packageName;
  final String appName;
}

class PlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.refocus/platform',
  );

  static Future<bool> hasUsagePermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('hasUsagePermission');
      return res ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod<void>('requestUsagePermission');
    } catch (_) {}
  }

  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final List<dynamic>? res = await _channel.invokeMethod(
        'getInstalledApps',
      );
      if (res == null) return [];
      return res
          .whereType<Map>()
          .map(
            (m) => AppInfo(
              packageName: m['packageName']?.toString() ?? '',
              appName: m['appName']?.toString() ?? '',
            ),
          )
          .where((a) => a.packageName.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<String?> getForegroundApp() async {
    try {
      return await _channel.invokeMethod<String?>('getForegroundApp');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasBatteryOptimizationIgnored() async {
    try {
      final res = await _channel.invokeMethod<bool>(
        'hasBatteryOptimizationIgnored',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimization');
    } catch (_) {}
  }

  static Future<bool> hasOverlayPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<void> showOverlayBlocker({
    required String title,
    required String message,
    int seconds = 5,
  }) async {
    try {
      await _channel.invokeMethod<void>('showOverlayBlocker', {
        'title': title,
        'message': message,
        'seconds': seconds,
      });
    } catch (_) {}
  }

  static Future<void> kickToHomeScreen() async {
    try {
      await _channel.invokeMethod<void>('kickToHomeScreen');
    } catch (_) {}
  }
}
