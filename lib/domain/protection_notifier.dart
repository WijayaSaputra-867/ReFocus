import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/platform_service.dart';
import 'protection_state.dart';

/// Single source of truth for protection engine, rules, and protected apps.
/// Uses SharedPreferences for persistence (PRD FR-01 through FR-10).
class ProtectionNotifier extends ChangeNotifier {
  ProtectionNotifier._();

  static Future<ProtectionNotifier> create() async {
    final n = ProtectionNotifier._();
    await n._load();
    n._startForegroundWatcher();
    return n;
  }

  late SharedPreferences _prefs;
  Timer? _ticker;
  Timer? _watcher;

  ProtectionSettings _settings = const ProtectionSettings();
  ProtectionSettings get settings => _settings;

  ProtectionSnapshot _snap = const ProtectionSnapshot();
  ProtectionSnapshot get snap => _snap;

  Set<String> _protectedApps = {
    'TikTok',
    'Instagram',
    'YouTube',
    'Mobile Legends',
  };
  Set<String> get protectedApps => Set.unmodifiable(_protectedApps);

  bool _onboardingCompleted = false;
  bool get onboardingCompleted => _onboardingCompleted;

  // ── Persistence keys ──────────────────────────────────────────────────────
  static const _kTrigger = 'trigger_seconds';
  static const _kLimit = 'daily_session_limit';
  static const _kCooldown = 'cooldown_seconds';
  static const _kSessions = 'sessions_today';
  static const _kDate = 'sessions_date';
  static const _kEnabled = 'protection_enabled';
  static const _kApps = 'protected_apps';
  static const _kElapsed = 'elapsed_seconds';
  static const _kCooldownRemaining = 'cooldown_remaining';
  static const _kStatus = 'protection_status';
  static const _kOnboardingCompleted = 'onboarding_completed';
  static const _kTotalDistraction = 'total_distraction_seconds';
  static const _kResisted = 'resisted_today';
  static const _kWeeklyLog = 'weekly_stats_log';

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _rolloverIfNewDay();

    _settings = ProtectionSettings(
      triggerSeconds: _prefs.getInt(_kTrigger) ?? 5 * 60,
      dailySessionLimit: _prefs.getInt(_kLimit) ?? 5,
      cooldownSeconds: _prefs.getInt(_kCooldown) ?? 15 * 60,
    );

    final savedApps = _prefs.getStringList(_kApps);
    if (savedApps != null) {
      _protectedApps = savedApps.toSet();
    }

    final savedStatusName = _prefs.getString(_kStatus);
    final savedStatus = ProtectionStatus.values.firstWhere(
      (e) => e.name == savedStatusName,
      orElse: () => ProtectionStatus.idle,
    );

    final savedCooldown = _prefs.getInt(_kCooldownRemaining) ?? 0;
    final savedElapsed = _prefs.getInt(_kElapsed) ?? 0;
    final sessions = _prefs.getInt(_kSessions) ?? 0;
    final enabled = _prefs.getBool(_kEnabled) ?? true;
    final totalDistraction = _prefs.getInt(_kTotalDistraction) ?? 0;
    final resisted = _prefs.getInt(_kResisted) ?? 0;

    _snap = ProtectionSnapshot(
      status: savedStatus,
      elapsedSeconds: savedElapsed,
      sessionsToday: sessions,
      cooldownRemainingSeconds: savedCooldown,
      protectionEnabled: enabled,
      totalDistractionSecondsToday: totalDistraction,
      resistedToday: resisted,
    );

    _onboardingCompleted = _prefs.getBool(_kOnboardingCompleted) ?? false;

    if (_snap.status == ProtectionStatus.cooldown && savedCooldown > 0) {
      _startCooldownTicker();
    }
  }

  void _rolloverIfNewDay() {
    final today = _todayKey();
    if (_prefs.getString(_kDate) != today) {
      // Save yesterday's totals to weekly log before resetting
      _appendToWeeklyLog(
        date: _prefs.getString(_kDate) ?? today,
        distractionSeconds: _prefs.getInt(_kTotalDistraction) ?? 0,
        sessions: _prefs.getInt(_kSessions) ?? 0,
        resisted: _prefs.getInt(_kResisted) ?? 0,
      );
      _prefs.setString(_kDate, today);
      _prefs.setInt(_kSessions, 0);
      _prefs.setInt(_kElapsed, 0);
      _prefs.setInt(_kCooldownRemaining, 0);
      _prefs.setString(_kStatus, ProtectionStatus.idle.name);
      _prefs.setInt(_kTotalDistraction, 0);
      _prefs.setInt(_kResisted, 0);
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _saveSnap() {
    _prefs.setString(_kStatus, _snap.status.name);
    _prefs.setInt(_kElapsed, _snap.elapsedSeconds);
    _prefs.setInt(_kCooldownRemaining, _snap.cooldownRemainingSeconds);
    _prefs.setInt(_kSessions, _snap.sessionsToday);
    _prefs.setInt(_kTotalDistraction, _snap.totalDistractionSecondsToday);
    _prefs.setInt(_kResisted, _snap.resistedToday);
  }

  // ── Onboarding ────────────────────────────────────────────────────────────

  void completeOnboarding() {
    _onboardingCompleted = true;
    _prefs.setBool(_kOnboardingCompleted, true);
    notifyListeners();
  }

  void resetOnboarding() {
    _onboardingCompleted = false;
    _prefs.setBool(_kOnboardingCompleted, false);
    notifyListeners();
  }

  // ── App Management (FR-01) ────────────────────────────────────────────────

  void toggleApp(String appOrPkg) {
    if (_protectedApps.contains(appOrPkg)) {
      _protectedApps.remove(appOrPkg);
    } else {
      _protectedApps.add(appOrPkg);
    }
    _prefs.setStringList(_kApps, _protectedApps.toList());
    notifyListeners();
  }

  bool isAppProtected(String appOrPkg) {
    if (_protectedApps.contains(appOrPkg)) return true;
    final lower = appOrPkg.toLowerCase();
    for (final p in _protectedApps) {
      final pLower = p.toLowerCase();
      if (lower.contains(pLower) || pLower.contains(lower)) {
        return true;
      }
    }
    return false;
  }

  // ── Settings (FR-02, FR-03, FR-10) ────────────────────────────────────────

  void updateSettings(ProtectionSettings s) {
    _settings = s;
    _prefs.setInt(_kTrigger, s.triggerSeconds);
    _prefs.setInt(_kLimit, s.dailySessionLimit);
    _prefs.setInt(_kCooldown, s.cooldownSeconds);
    notifyListeners();
  }

  void toggleProtection() {
    final enabled = !_snap.protectionEnabled;
    _prefs.setBool(_kEnabled, enabled);
    _stopTicker();
    _snap = _snap.copyWith(
      protectionEnabled: enabled,
      status: ProtectionStatus.idle,
      elapsedSeconds: 0,
      cooldownRemainingSeconds: 0,
    );
    _saveSnap();
    if (enabled) {
      _startForegroundWatcher();
    } else {
      _watcher?.cancel();
      _watcher = null;
    }
    notifyListeners();
  }

  // ── Native Foreground Watcher (FR-04, FR-05, FR-06) ──────────────────────

  void _startForegroundWatcher() {
    _watcher?.cancel();
    // Poll foreground app every 1 second via Android UsageStats
    _watcher = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_snap.protectionEnabled) return;
      if (_snap.status == ProtectionStatus.dailyLocked ||
          _snap.status == ProtectionStatus.cooldown) {
        return;
      }

      final foregroundApp = await PlatformService.getForegroundApp();
      if (foregroundApp == null || foregroundApp.isEmpty) return;

      if (isAppProtected(foregroundApp)) {
        if (_snap.status != ProtectionStatus.distracting) {
          onAppForegrounded(foregroundApp);
        }
      } else {
        if (_snap.status == ProtectionStatus.distracting) {
          onAppBackgrounded();
        }
      }
    });
  }

  // ── Distraction Engine (FR-04, FR-05, FR-06, FR-07, FR-08, FR-09) ─────────

  void onAppForegrounded(String appName) {
    if (!_snap.protectionEnabled) return;
    if (_snap.status == ProtectionStatus.dailyLocked) return;
    if (_snap.status == ProtectionStatus.cooldown) return;

    if (isAppProtected(appName)) {
      _snap = _snap.copyWith(status: ProtectionStatus.distracting);
      _startDistractionTicker();
      _saveSnap();
      notifyListeners();
    } else {
      onAppBackgrounded();
    }
  }

  void onAppBackgrounded() {
    if (_snap.status == ProtectionStatus.distracting) {
      _stopTicker();
      _snap = _snap.copyWith(status: ProtectionStatus.idle);
      _saveSnap();
      notifyListeners();
    }
  }

  void _startDistractionTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final nextElapsed = _snap.elapsedSeconds + 1;
      final nextTotal = _snap.totalDistractionSecondsToday + 1;
      if (nextElapsed >= _settings.triggerSeconds) {
        final nextSessions = _snap.sessionsToday + 1;
        if (nextSessions >= _settings.dailySessionLimit) {
          _stopTicker();
          _snap = _snap.copyWith(
            status: ProtectionStatus.dailyLocked,
            elapsedSeconds: 0,
            sessionsToday: nextSessions,
            cooldownRemainingSeconds: 0,
            totalDistractionSecondsToday: nextTotal,
          );
        } else {
          _snap = _snap.copyWith(
            status: ProtectionStatus.cooldown,
            elapsedSeconds: 0,
            sessionsToday: nextSessions,
            cooldownRemainingSeconds: _settings.cooldownSeconds,
            totalDistractionSecondsToday: nextTotal,
          );
          _startCooldownTicker();
        }
      } else {
        _snap = _snap.copyWith(
          elapsedSeconds: nextElapsed,
          totalDistractionSecondsToday: nextTotal,
        );
      }
      _saveSnap();
      notifyListeners();
    });
  }

  void _startCooldownTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _snap.cooldownRemainingSeconds - 1;
      if (remaining <= 0) {
        _stopTicker();
        // Cooldown finished without user re-entering — count as resisted
        _snap = _snap.copyWith(
          status: ProtectionStatus.idle,
          cooldownRemainingSeconds: 0,
          resistedToday: _snap.resistedToday + 1,
        );
      } else {
        _snap = _snap.copyWith(cooldownRemainingSeconds: remaining);
      }
      _saveSnap();
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void applySnapshot(ProtectionSnapshot snap) {
    _snap = snap;
    _saveSnap();
    notifyListeners();
  }

  // ── Weekly stats log ──────────────────────────────────────────────────────

  /// Returns up to 7 days of stats, newest last.
  List<Map<String, dynamic>> getWeeklyLog() {
    final raw = _prefs.getString(_kWeeklyLog);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  void _appendToWeeklyLog({
    required String date,
    required int distractionSeconds,
    required int sessions,
    required int resisted,
  }) {
    if (distractionSeconds == 0 && sessions == 0) return; // skip empty days
    final log = getWeeklyLog();
    // Remove existing entry for same date (idempotent)
    log.removeWhere((e) => e['date'] == date);
    log.add({
      'date': date,
      'distractionSeconds': distractionSeconds,
      'sessions': sessions,
      'resisted': resisted,
    });
    // Keep only last 7 days
    final trimmed = log.length > 7 ? log.sublist(log.length - 7) : log;
    _prefs.setString(_kWeeklyLog, jsonEncode(trimmed));
  }

  /// Save today's data into the weekly log (call when app goes to background).
  void flushTodayToLog() {
    _appendToWeeklyLog(
      date: _todayKey(),
      distractionSeconds: _snap.totalDistractionSecondsToday,
      sessions: _snap.sessionsToday,
      resisted: _snap.resistedToday,
    );
  }

  void debugAdvanceState() {
    final next = ProtectionStatus
        .values[(_snap.status.index + 1) % ProtectionStatus.values.length];
    _stopTicker();
    _snap = _snap.copyWith(
      status: next,
      elapsedSeconds: next == ProtectionStatus.distracting ? 142 : 0,
      cooldownRemainingSeconds: next == ProtectionStatus.cooldown ? 840 : 0,
      sessionsToday: next == ProtectionStatus.cooldown
          ? _snap.sessionsToday + 1
          : _snap.sessionsToday,
    );
    if (next == ProtectionStatus.cooldown) {
      _startCooldownTicker();
    }
    _saveSnap();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    _watcher?.cancel();
    super.dispose();
  }
}
