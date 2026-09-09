import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 6: Optional Advanced Features Service.
/// Implements widgets state bridge, per-category rules, and website blocking list.
class AdvancedFeaturesService extends ChangeNotifier {
  static const String _keyBlockedWebsites = 'refocus_blocked_websites';
  static const String _keyCategoryRules = 'refocus_category_rules';
  static const String _keyWidgetState = 'widget_refocus_state';

  List<String> _blockedWebsites = [
    'tiktok.com',
    'instagram.com',
    'facebook.com',
    'x.com',
    'reddit.com',
  ];

  Map<String, int> _categoryRules = {
    'Social': 15 * 60, // 15 mins default
    'Entertainment': 30 * 60,
    'Games': 20 * 60,
  };

  List<String> get blockedWebsites => List.unmodifiable(_blockedWebsites);
  Map<String, int> get categoryRules => Map.unmodifiable(_categoryRules);

  AdvancedFeaturesService._();

  static Future<AdvancedFeaturesService> create() async {
    final service = AdvancedFeaturesService._();
    final prefs = await SharedPreferences.getInstance();

    final savedSites = prefs.getStringList(_keyBlockedWebsites);
    if (savedSites != null) {
      service._blockedWebsites = savedSites;
    }

    final savedCategories = prefs.getString(_keyCategoryRules);
    if (savedCategories != null) {
      try {
        final decoded = jsonDecode(savedCategories) as Map<String, dynamic>;
        service._categoryRules = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }

    return service;
  }

  /// Website blocking
  Future<void> addBlockedWebsite(String domain) async {
    final clean = domain.trim().toLowerCase().replaceAll(
      RegExp(r'^https?:\/\/'),
      '',
    );
    if (clean.isNotEmpty && !_blockedWebsites.contains(clean)) {
      _blockedWebsites.add(clean);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyBlockedWebsites, _blockedWebsites);
      notifyListeners();
    }
  }

  Future<void> removeBlockedWebsite(String domain) async {
    if (_blockedWebsites.remove(domain)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyBlockedWebsites, _blockedWebsites);
      notifyListeners();
    }
  }

  /// Per-category rules
  Future<void> setCategoryLimit(String category, int limitSeconds) async {
    _categoryRules[category] = limitSeconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCategoryRules, jsonEncode(_categoryRules));
    notifyListeners();
  }

  /// Widgets bridge: writes current state to SharedPreferences for Android Glance / AppWidget
  Future<void> updateWidgetState({
    required String status,
    required int sessionsRemaining,
    required int distractionElapsedSeconds,
    required bool focusActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'status': status,
      'sessionsRemaining': sessionsRemaining,
      'distractionElapsedSeconds': distractionElapsedSeconds,
      'focusActive': focusActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_keyWidgetState, payload);
  }
}
