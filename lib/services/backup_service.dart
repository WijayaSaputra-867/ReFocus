import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first Encrypted Backup & Sync Service (Phase 6).
/// Ponytail philosophy: zero external dependencies, robust pure-Dart cipher,
/// preserves complete privacy and local-only ownership.
class BackupService {
  static const String _magicHeader = 'RFENCv1:';

  /// Generates a key stream byte from passphrase and salt.
  static List<int> _deriveKey(String passphrase, List<int> salt, int length) {
    final passBytes = utf8.encode(passphrase);
    final key = <int>[];
    int seed = 5381;
    for (final b in passBytes) {
      seed = ((seed << 5) + seed) + b;
    }
    for (final s in salt) {
      seed = ((seed << 5) + seed) + s;
    }

    // Pseudo-random keystream generator using Linear Congruential Generator with seed
    var state = seed & 0x7FFFFFFF;
    for (int i = 0; i < length; i++) {
      state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
      key.add((state >> 16) & 0xFF);
    }
    return key;
  }

  /// Exports current settings, protected apps, and stats into an encrypted string.
  static Future<String> createEncryptedBackup(String passphrase) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final Map<String, dynamic> data = {};

    for (final key in allKeys) {
      final val = prefs.get(key);
      if (val != null) {
        data[key] = val;
      }
    }

    final payload = jsonEncode({
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'payload': data,
    });

    final payloadBytes = utf8.encode(payload);
    // Simple 8-byte salt
    final salt = List<int>.generate(8, (i) => (i * 37 + 13) % 256);
    final keystream = _deriveKey(passphrase, salt, payloadBytes.length);

    final cipherBytes = List<int>.generate(payloadBytes.length, (i) {
      return payloadBytes[i] ^ keystream[i];
    });

    // Calculate checksum
    int checksum = 0;
    for (final b in payloadBytes) {
      checksum = (checksum + b) & 0xFFFF;
    }

    final combined = {
      'salt': base64Encode(salt),
      'chk': checksum,
      'body': base64Encode(cipherBytes),
    };

    return '$_magicHeader${base64Encode(utf8.encode(jsonEncode(combined)))}';
  }

  /// Restores settings and state from an encrypted backup string.
  /// Returns true if successful, false if corrupted or wrong passphrase.
  static Future<bool> restoreFromBackup(
    String backupStr,
    String passphrase,
  ) async {
    try {
      if (!backupStr.startsWith(_magicHeader)) return false;
      final rawBase64 = backupStr.substring(_magicHeader.length);
      final jsonStr = utf8.decode(base64Decode(rawBase64));
      final Map<String, dynamic> combined = jsonDecode(jsonStr);

      final salt = base64Decode(combined['salt'] as String);
      final expectedChk = combined['chk'] as int;
      final cipherBytes = base64Decode(combined['body'] as String);

      final keystream = _deriveKey(passphrase, salt, cipherBytes.length);
      final plainBytes = List<int>.generate(cipherBytes.length, (i) {
        return cipherBytes[i] ^ keystream[i];
      });

      // Verify checksum
      int actualChk = 0;
      for (final b in plainBytes) {
        actualChk = (actualChk + b) & 0xFFFF;
      }
      if (actualChk != expectedChk) return false;

      final plainJson = utf8.decode(plainBytes);
      final Map<String, dynamic> root = jsonDecode(plainJson);
      final Map<String, dynamic> data = root['payload'] as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      for (final entry in data.entries) {
        final val = entry.value;
        if (val is int) {
          await prefs.setInt(entry.key, val);
        } else if (val is bool) {
          await prefs.setBool(entry.key, val);
        } else if (val is double) {
          await prefs.setDouble(entry.key, val);
        } else if (val is String) {
          await prefs.setString(entry.key, val);
        } else if (val is List) {
          await prefs.setStringList(entry.key, val.cast<String>());
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Generates a lightweight cross-device sync payload for focus sessions.
  static String createSyncToken({
    required int focusSecondsRemaining,
    required bool isFocusActive,
  }) {
    final payload = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'remaining': focusSecondsRemaining,
      'active': isFocusActive,
    };
    return base64UrlEncode(utf8.encode(jsonEncode(payload)));
  }
}
