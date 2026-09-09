import 'package:flutter_test/flutter_test.dart';
import 'package:refocus/domain/protection_notifier.dart';
import 'package:refocus/domain/protection_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'protection notifier initializes with default settings and protected apps',
    () async {
      final notifier = await ProtectionNotifier.create();

      expect(notifier.settings.triggerSeconds, 300);
      expect(notifier.settings.dailySessionLimit, 5);
      expect(notifier.snap.status, ProtectionStatus.idle);
      // Display names
      expect(notifier.isAppProtected('TikTok'), isTrue);
      expect(notifier.isAppProtected('YouTube'), isTrue);
      // Package names
      expect(notifier.isAppProtected('com.zhiliaoapp.musically'), isTrue);
      expect(notifier.isAppProtected('com.ss.android.ugc.trill'), isTrue);
      expect(notifier.isAppProtected('com.google.android.youtube'), isTrue);
      expect(notifier.isAppProtected('com.instagram.android'), isTrue);
      // Non-protected and system
      expect(notifier.isAppProtected('com.example.refocus'), isFalse);
      expect(notifier.isAppProtected('com.android.launcher'), isFalse);
      expect(notifier.isAppProtected('NonExistentApp'), isFalse);
    },
  );

  test('toggleApp adds and removes apps and persists', () async {
    final notifier = await ProtectionNotifier.create();

    notifier.toggleApp('Netflix');
    expect(notifier.isAppProtected('Netflix'), isTrue);

    notifier.toggleApp('Netflix');
    expect(notifier.isAppProtected('Netflix'), isFalse);
  });

  test('updateSettings updates rules and persists', () async {
    final notifier = await ProtectionNotifier.create();

    notifier.updateSettings(
      const ProtectionSettings(
        triggerSeconds: 120,
        dailySessionLimit: 3,
        cooldownSeconds: 600,
      ),
    );

    expect(notifier.settings.triggerSeconds, 120);
    expect(notifier.settings.dailySessionLimit, 3);
    expect(notifier.settings.cooldownSeconds, 600);
  });

  test('app foreground and background state transitions', () async {
    final notifier = await ProtectionNotifier.create();

    // Foreground non-protected app: remains idle
    notifier.onAppForegrounded('Calculator');
    expect(notifier.snap.status, ProtectionStatus.idle);

    // Foreground protected app: enters distracting
    notifier.onAppForegrounded('TikTok');
    expect(notifier.snap.status, ProtectionStatus.distracting);

    // Leave protected app: pauses and returns to idle
    notifier.onAppBackgrounded();
    expect(notifier.snap.status, ProtectionStatus.idle);
  });
}
