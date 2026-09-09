import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, local-first translation system (Phase 5).
/// Ponytail philosophy: clean, zero external dependencies, standard Map dictionary.
class TranslationService extends ChangeNotifier {
  static const String _prefKey = 'app_language';
  String _locale = 'en';

  String get locale => _locale;

  static final Map<String, Map<String, String>> _strings = {
    'en': {
      'app_title': 'Refocus',
      'tagline': 'Take back your attention.',
      'home': 'Home',
      'apps': 'Apps',
      'rules': 'Rules',
      'stats': 'Stats',
      'permissions': 'Permissions',
      'focus': 'Focus',
      'protection_on': 'PROTECTION ON',
      'protection_off': 'PROTECTION PAUSED',
      'trigger_duration': 'Trigger duration',
      'daily_limit': 'Daily session limit',
      'cooldown_duration': 'Cooldown duration',
      'save_rules': 'Save rules',
      'rules_saved': 'Rules saved.',
      'language': 'Language',
      'backup_restore': 'Backup & Sync (Phase 6)',
      'website_blocking': 'Website Blocking',
      'category_rules': 'Category Rules',
    },
    'id': {
      'app_title': 'Refocus',
      'tagline': 'Kembalikan fokus dan perhatianmu.',
      'home': 'Beranda',
      'apps': 'Aplikasi',
      'rules': 'Aturan',
      'stats': 'Statistik',
      'permissions': 'Izin',
      'focus': 'Fokus',
      'protection_on': 'PROTEKSI AKTIF',
      'protection_off': 'PROTEKSI DIJEDA',
      'trigger_duration': 'Durasi pemicu',
      'daily_limit': 'Batas sesi harian',
      'cooldown_duration': 'Durasi pendinginan',
      'save_rules': 'Simpan aturan',
      'rules_saved': 'Aturan berhasil disimpan.',
      'language': 'Bahasa',
      'backup_restore': 'Cadangan & Sinkronisasi (Fase 6)',
      'website_blocking': 'Blokir Situs Web',
      'category_rules': 'Aturan per Kategori',
    },
  };

  TranslationService._(this._locale);

  static Future<TranslationService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_prefKey) ?? 'en';
    return TranslationService._(savedLocale);
  }

  Future<void> setLocale(String langCode) async {
    if (_strings.containsKey(langCode) && _locale != langCode) {
      _locale = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
      notifyListeners();
    }
  }

  String t(String key) {
    return _strings[_locale]?[key] ?? _strings['en']?[key] ?? key;
  }
}
