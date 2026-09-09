import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refocus/services/backup_service.dart';
import 'package:refocus/services/translation_service.dart';
import 'package:refocus/services/advanced_features_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5: TranslationService', () {
    test('defaults to en and switches to id', () async {
      SharedPreferences.setMockInitialValues({});
      final service = await TranslationService.create();
      expect(service.locale, 'en');
      expect(service.t('rules'), 'Rules');

      await service.setLocale('id');
      expect(service.locale, 'id');
      expect(service.t('rules'), 'Aturan');
    });
  });

  group('Phase 6: BackupService', () {
    test('creates encrypted backup and restores successfully', () async {
      SharedPreferences.setMockInitialValues({
        'trigger_seconds': 300,
        'daily_session_limit': 4,
        'protected_apps': ['TikTok', 'Instagram'],
      });

      const pass = 'super-secret-passphrase';
      final backupStr = await BackupService.createEncryptedBackup(pass);

      expect(backupStr.startsWith('RFENCv1:'), isTrue);

      // Mutate preferences to simulate fresh/corrupted device
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      expect(prefs.getKeys().isEmpty, isTrue);

      // Wrong passphrase should fail
      final failRestore = await BackupService.restoreFromBackup(
        backupStr,
        'wrong-pass',
      );
      expect(failRestore, isFalse);

      // Correct passphrase restores data
      final okRestore = await BackupService.restoreFromBackup(backupStr, pass);
      expect(okRestore, isTrue);
      expect(prefs.getInt('trigger_seconds'), 300);
      expect(prefs.getInt('daily_session_limit'), 4);
      expect(prefs.getStringList('protected_apps'), ['TikTok', 'Instagram']);
    });

    test('creates sync token for cross-device focus', () {
      final token = BackupService.createSyncToken(
        focusSecondsRemaining: 1500,
        isFocusActive: true,
      );
      expect(token.isNotEmpty, isTrue);
    });
  });

  group('Phase 6: AdvancedFeaturesService', () {
    test('manages blocked websites and category rules', () async {
      SharedPreferences.setMockInitialValues({});
      final service = await AdvancedFeaturesService.create();

      expect(service.blockedWebsites.contains('tiktok.com'), isTrue);
      await service.addBlockedWebsite('https://distraction.test');
      expect(service.blockedWebsites.contains('distraction.test'), isTrue);

      await service.removeBlockedWebsite('distraction.test');
      expect(service.blockedWebsites.contains('distraction.test'), isFalse);

      await service.setCategoryLimit('Social', 1200);
      expect(service.categoryRules['Social'], 1200);

      await service.updateWidgetState(
        status: 'idle',
        sessionsRemaining: 4,
        distractionElapsedSeconds: 0,
        focusActive: false,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('widget_refocus_state'), isTrue);
    });
  });
}
