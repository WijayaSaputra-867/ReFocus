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
    if (n._snap.protectionEnabled) {
      PlatformService.startForegroundService();
    }
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
    if (savedApps != null && savedApps.isNotEmpty) {
      _protectedApps = savedApps.toSet();
    } else {
      _prefs.setStringList(_kApps, _protectedApps.toList());
    }

    if (!_prefs.containsKey(_kTrigger)) {
      _prefs.setInt(_kTrigger, _settings.triggerSeconds);
      _prefs.setInt(_kLimit, _settings.dailySessionLimit);
      _prefs.setInt(_kCooldown, _settings.cooldownSeconds);
      _prefs.setBool(_kEnabled, false);
    }

    final savedStatusName = _prefs.getString(_kStatus);
    final savedStatus = (savedStatusName == 'daily_locked')
        ? ProtectionStatus.dailyLocked
        : ProtectionStatus.values.firstWhere(
            (e) => e.name == savedStatusName,
            orElse: () => ProtectionStatus.idle,
          );

    final savedCooldown = _prefs.getInt(_kCooldownRemaining) ?? 0;
    final savedElapsed = _prefs.getInt(_kElapsed) ?? 0;
    final rawSessions = _prefs.getInt(_kSessions) ?? 0;
    final sessions = rawSessions.clamp(0, _settings.dailySessionLimit);
    final enabled = _prefs.getBool(_kEnabled) ?? false;
    final totalDistraction = _prefs.getInt(_kTotalDistraction) ?? 0;
    final resisted = _prefs.getInt(_kResisted) ?? 0;

    final isLocked = sessions >= _settings.dailySessionLimit;
    _snap = ProtectionSnapshot(
      status: isLocked ? ProtectionStatus.dailyLocked : savedStatus,
      elapsedSeconds: isLocked ? 0 : savedElapsed,
      sessionsToday: sessions,
      cooldownRemainingSeconds: isLocked ? 0 : savedCooldown,
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
    final storedElapsed = _prefs.getInt(_kElapsed) ?? 0;
    if (_snap.status == ProtectionStatus.idle && _snap.elapsedSeconds == 0) {
      _prefs.setInt(_kElapsed, 0);
    } else if (_snap.elapsedSeconds >= storedElapsed) {
      _prefs.setInt(_kElapsed, _snap.elapsedSeconds);
    }
    _prefs.setInt(_kCooldownRemaining, _snap.cooldownRemainingSeconds);
    if (_snap.status == ProtectionStatus.cooldown &&
        _snap.cooldownRemainingSeconds > 0) {
      final existingUntil = _prefs.getInt('cooldown_until_epoch_ms') ?? 0;
      if (existingUntil <= DateTime.now().millisecondsSinceEpoch) {
        final until =
            DateTime.now().millisecondsSinceEpoch +
            (_snap.cooldownRemainingSeconds * 1000);
        _prefs.setInt('cooldown_until_epoch_ms', until);
      }
    } else if (_snap.status != ProtectionStatus.cooldown) {
      _prefs.setInt('cooldown_until_epoch_ms', 0);
    }
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

  static const Map<String, List<String>> _knownAppAliases = {
    'tiktok': [
      'com.zhiliaoapp.musically',
      'com.ss.android.ugc.trill',
      'com.zhiliaoapp.musically.go',
      'tiktok',
    ],
    'instagram': ['com.instagram.android', 'instagram'],
    'youtube': ['com.google.android.youtube', 'youtube'],
    'mobile legends': ['com.mobile.legends', 'mobile legends', 'mobilelegends'],
    'facebook': ['com.facebook.katana', 'com.facebook.lite', 'facebook'],
    'twitter': ['com.twitter.android', 'twitter', 'x'],
  };

  void toggleApp(String appOrPkg) {
    if (isAppProtected(appOrPkg)) {
      final lower = appOrPkg.toLowerCase().trim();
      _protectedApps.remove(appOrPkg);
      _protectedApps.removeWhere((p) {
        final pLower = p.toLowerCase().trim();
        if (pLower == lower) return true;
        for (final aliases in _knownAppAliases.values) {
          if (aliases.contains(lower) && aliases.contains(pLower)) return true;
        }
        return false;
      });
    } else {
      _protectedApps.add(appOrPkg);
    }
    _prefs.setStringList(_kApps, _protectedApps.toList());
    notifyListeners();
  }

  bool isAppProtected(String appOrPkg) {
    if (_protectedApps.contains(appOrPkg)) return true;
    final lower = appOrPkg.toLowerCase().trim();
    if (lower == 'com.example.refocus') return false;

    for (final p in _protectedApps) {
      final pLower = p.toLowerCase().trim();
      if (lower == pLower) return true;

      for (final aliases in _knownAppAliases.values) {
        final hasTarget = aliases.any((a) => lower == a || lower.contains(a));
        final hasProtected = aliases.any(
          (a) => pLower == a || pLower.contains(a),
        );
        if (hasTarget && hasProtected) return true;
      }

      if (pLower.length >= 3 && lower.contains(pLower)) return true;
    }
    return false;
  }

  // ── Settings (FR-02, FR-03, FR-10) ────────────────────────────────────────

  void updateSettings(ProtectionSettings s) {
    _settings = s;
    _prefs.setInt(_kTrigger, s.triggerSeconds);
    _prefs.setInt(_kLimit, s.dailySessionLimit);
    _prefs.setInt(_kCooldown, s.cooldownSeconds);
    if (_snap.sessionsToday >= s.dailySessionLimit &&
        _snap.status != ProtectionStatus.dailyLocked) {
      _stopTicker();
      _snap = _snap.copyWith(
        status: ProtectionStatus.dailyLocked,
        elapsedSeconds: 0,
        cooldownRemainingSeconds: 0,
      );
      _saveSnap();
    }
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
      PlatformService.startForegroundService();
    } else {
      _watcher?.cancel();
      _watcher = null;
      PlatformService.stopForegroundService();
    }
    notifyListeners();
  }

  String _currentForegroundApp = '';
  DateTime? _lastBlockerShownAt;

  String _displayNameFor(String appOrPkg) {
    final lower = appOrPkg.toLowerCase().trim();
    for (final entry in _knownAppAliases.entries) {
      if (entry.key == lower || entry.value.contains(lower)) {
        return entry.key.toUpperCase();
      }
    }
    return appOrPkg.isNotEmpty ? appOrPkg : 'aplikasi ini';
  }

  void _triggerOverlayBlocker(String appName, {bool? isDailyLock}) {
    final now = DateTime.now();
    if (_lastBlockerShownAt != null &&
        now.difference(_lastBlockerShownAt!).inSeconds < 4) {
      return;
    }
    _lastBlockerShownAt = now;

    final isLock =
        isDailyLock ?? (_snap.status == ProtectionStatus.dailyLocked);
    final title = isLock ? 'Batas Harian Tercapai' : 'Waktunya Istirahat';
    final displayName = _displayNameFor(appName);
    final cooldownRem = _snap.cooldownRemainingSeconds;
    final message = isLock
        ? 'Jatah sesi harian Anda untuk $displayName sudah habis. Kembali lagi besok.'
        : (_snap.status == ProtectionStatus.cooldown && cooldownRem > 0)
        ? 'Aplikasi $displayName sedang dalam masa jeda (cooldown). Waktu istirahat tersisa: ${(cooldownRem ~/ 60).toString().padLeft(2, '0')}:${(cooldownRem % 60).toString().padLeft(2, '0')}.'
        : 'Waktu buka $displayName sudah habis. Tarik napas sejenak.';

    PlatformService.showOverlayBlocker(
      title: title,
      message: message,
      seconds: 5,
    );
  }

  // ── Sync with Native Storage ──────────────────────────────────────────────

  Future<void> reloadFromStorage() async {
    try {
      final nativeState = await PlatformService.getProtectionState();
      if (nativeState != null) {
        final savedStatusName = nativeState['status'] as String? ?? 'idle';
        var savedStatus = (savedStatusName == 'daily_locked')
            ? ProtectionStatus.dailyLocked
            : ProtectionStatus.values.firstWhere(
                (e) => e.name == savedStatusName,
                orElse: () => ProtectionStatus.idle,
              );
        final savedElapsed = (nativeState['elapsedSeconds'] as int?) ?? 0;
        final savedCooldown = (nativeState['cooldownRemaining'] as int?) ?? 0;
        final sessions = ((nativeState['sessionsToday'] as int?) ?? 0).clamp(
          0,
          _settings.dailySessionLimit,
        );
        final totalDistraction =
            (nativeState['totalDistractionSeconds'] as int?) ?? 0;
        final resisted = (nativeState['resistedToday'] as int?) ?? 0;
        final enabled = _snap.protectionEnabled;

        final isLocked = sessions >= _settings.dailySessionLimit;
        final newSnap = ProtectionSnapshot(
          status: isLocked ? ProtectionStatus.dailyLocked : savedStatus,
          elapsedSeconds: isLocked ? 0 : savedElapsed,
          sessionsToday: sessions,
          cooldownRemainingSeconds: isLocked ? 0 : savedCooldown,
          protectionEnabled: enabled,
          totalDistractionSecondsToday: totalDistraction,
          resistedToday: resisted,
        );
        if (_snap != newSnap) {
          _snap = newSnap;
          notifyListeners();
        }
        return;
      }
    } catch (_) {}

    try {
      await _prefs.reload();
      final savedStatusName = _prefs.getString(_kStatus);
      var savedStatus = (savedStatusName == 'daily_locked')
          ? ProtectionStatus.dailyLocked
          : ProtectionStatus.values.firstWhere(
              (e) => e.name == savedStatusName,
              orElse: () => ProtectionStatus.idle,
            );

      final savedCooldownUntil = _prefs.getInt('cooldown_until_epoch_ms') ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      int savedCooldown = 0;
      if (savedCooldownUntil > nowMs) {
        savedCooldown = ((savedCooldownUntil - nowMs) / 1000).ceil();
      } else {
        savedCooldown = _prefs.getInt(_kCooldownRemaining) ?? 0;
      }

      final rawSessions = _prefs.getInt(_kSessions) ?? 0;
      var sessions = rawSessions.clamp(0, _settings.dailySessionLimit);

      // Cooldown naturally elapsed while app was closed or swiped away
      if (savedStatus == ProtectionStatus.cooldown &&
          savedCooldownUntil > 0 &&
          nowMs >= savedCooldownUntil) {
        sessions = (sessions + 1).clamp(0, _settings.dailySessionLimit);
        savedStatus = (sessions >= _settings.dailySessionLimit)
            ? ProtectionStatus.dailyLocked
            : ProtectionStatus.idle;
        savedCooldown = 0;
        _prefs.setInt('cooldown_until_epoch_ms', 0);
        _prefs.setInt(_kCooldownRemaining, 0);
        _prefs.setString(_kStatus, savedStatus.name);
        _prefs.setInt(_kSessions, sessions);
      }

      final savedElapsed = _prefs.getInt(_kElapsed) ?? 0;
      final enabled = _prefs.getBool(_kEnabled) ?? true;
      final totalDistraction = _prefs.getInt(_kTotalDistraction) ?? 0;
      final resisted = _prefs.getInt(_kResisted) ?? 0;

      final isLocked = sessions >= _settings.dailySessionLimit;
      final newSnap = ProtectionSnapshot(
        status: isLocked ? ProtectionStatus.dailyLocked : savedStatus,
        elapsedSeconds: isLocked ? 0 : savedElapsed,
        sessionsToday: sessions,
        cooldownRemainingSeconds: isLocked ? 0 : savedCooldown,
        protectionEnabled: enabled,
        totalDistractionSecondsToday: totalDistraction,
        resistedToday: resisted,
      );
      if (_snap != newSnap) {
        _snap = newSnap;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Native Foreground Watcher (FR-04, FR-05, FR-06) ──────────────────────

  void _startForegroundWatcher() {
    _watcher?.cancel();
    // Poll foreground app every 1 second to update UI state and block apps during cooldown/dailyLocked.
    _watcher = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_snap.protectionEnabled) return;
      await reloadFromStorage();

      final foregroundApp = await PlatformService.getForegroundApp();
      if (foregroundApp == null || foregroundApp.isEmpty) return;

      if (isAppProtected(foregroundApp)) {
        if (_snap.status == ProtectionStatus.dailyLocked ||
            _snap.sessionsToday >= _settings.dailySessionLimit ||
            _snap.status == ProtectionStatus.cooldown) {
          _triggerOverlayBlocker(foregroundApp);
        } else if (_snap.status != ProtectionStatus.distracting) {
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
    if (_snap.status == ProtectionStatus.dailyLocked ||
        _snap.sessionsToday >= _settings.dailySessionLimit ||
        _snap.status == ProtectionStatus.cooldown) {
      if (_snap.status != ProtectionStatus.dailyLocked &&
          _snap.sessionsToday >= _settings.dailySessionLimit) {
        _snap = _snap.copyWith(status: ProtectionStatus.dailyLocked);
        _saveSnap();
        notifyListeners();
      }
      _triggerOverlayBlocker(appName);
      return;
    }

    if (isAppProtected(appName)) {
      _currentForegroundApp = appName;
      final storedElapsed = _prefs.getInt(_kElapsed) ?? 0;
      final currentElapsed = storedElapsed > _snap.elapsedSeconds
          ? storedElapsed
          : _snap.elapsedSeconds;
      _snap = _snap.copyWith(
        status: ProtectionStatus.distracting,
        elapsedSeconds: currentElapsed,
      );
      _startDistractionTicker();
      _saveSnap();
      notifyListeners();
    } else {
      onAppBackgrounded();
    }
  }

  void onAppBackgrounded() {
    if (_snap.status == ProtectionStatus.distracting) {
      // Refocus itself can be swiped away while the user is still inside a protected app.
      // In that case, we must not treat the protected app as "left" just because the app
      // went to the background. Keep the distraction timer alive until we know the app is no
      // longer protected or the user actually left that app.
      if (_currentForegroundApp.isNotEmpty &&
          isAppProtected(_currentForegroundApp)) {
        return;
      }

      _stopTicker();
      _snap = _snap.copyWith(status: ProtectionStatus.idle);
      // Keeps elapsedSeconds paused (not reset to 0)
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
        _stopTicker();
        final untilMs =
            DateTime.now().millisecondsSinceEpoch +
            (_settings.cooldownSeconds * 1000);
        _prefs.setInt('cooldown_until_epoch_ms', untilMs);
        _snap = _snap.copyWith(
          status: ProtectionStatus.cooldown,
          elapsedSeconds: 0,
          cooldownRemainingSeconds: _settings.cooldownSeconds,
          totalDistractionSecondsToday: nextTotal,
        );
        _startCooldownTicker();
        _triggerOverlayBlocker(_currentForegroundApp, isDailyLock: false);
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
        final nextSessions = (_snap.sessionsToday + 1).clamp(
          0,
          _settings.dailySessionLimit,
        );
        final isMax = nextSessions >= _settings.dailySessionLimit;
        _snap = _snap.copyWith(
          status: isMax ? ProtectionStatus.dailyLocked : ProtectionStatus.idle,
          sessionsToday: nextSessions,
          cooldownRemainingSeconds: 0,
          elapsedSeconds: 0,
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
      elapsedSeconds: 0,
      cooldownRemainingSeconds: next == ProtectionStatus.cooldown
          ? _settings.cooldownSeconds
          : 0,
      sessionsToday: next == ProtectionStatus.cooldown
          ? (_snap.sessionsToday + 1).clamp(0, _settings.dailySessionLimit)
          : _snap.sessionsToday.clamp(0, _settings.dailySessionLimit),
    );
    if (next == ProtectionStatus.distracting) {
      _currentForegroundApp = 'TikTok';
      _startDistractionTicker();
    } else if (next == ProtectionStatus.cooldown) {
      _startCooldownTicker();
      _triggerOverlayBlocker('TikTok', isDailyLock: false);
    } else if (next == ProtectionStatus.dailyLocked) {
      _triggerOverlayBlocker('TikTok', isDailyLock: true);
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
