import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FocusStatus { idle, active, completed }

/// Manages a single focus session: countdown timer, completions, persistence.
/// Fully independent from ProtectionNotifier — existing protection engine
/// continues running during focus (protected apps are still monitored).
class FocusNotifier extends ChangeNotifier {
  FocusNotifier._();

  static Future<FocusNotifier> create() async {
    final n = FocusNotifier._();
    await n._load();
    return n;
  }

  late SharedPreferences _prefs;
  Timer? _timer;

  static const _kDuration = 'focus_duration_minutes';
  static const _kCompleted = 'focus_completed_today';
  static const _kDate = 'focus_date';

  FocusStatus _status = FocusStatus.idle;
  FocusStatus get status => _status;

  int _durationMinutes = 25;
  int get durationMinutes => _durationMinutes;

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  int _completedToday = 0;
  int get completedToday => _completedToday;

  bool get isActive => _status == FocusStatus.active;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _rolloverIfNewDay();
    _durationMinutes = _prefs.getInt(_kDuration) ?? 25;
    _completedToday = _prefs.getInt(_kCompleted) ?? 0;
    _remainingSeconds = _durationMinutes * 60;
  }

  void _rolloverIfNewDay() {
    final today = _todayKey();
    if (_prefs.getString(_kDate) != today) {
      _prefs.setString(_kDate, today);
      _prefs.setInt(_kCompleted, 0);
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Duration picker ────────────────────────────────────────────────────────

  static const availableMinutes = [15, 25, 45, 60];

  void setDuration(int minutes) {
    if (_status != FocusStatus.idle) return;
    _durationMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _prefs.setInt(_kDuration, minutes);
    notifyListeners();
  }

  // ── Session control ────────────────────────────────────────────────────────

  void startFocus() {
    if (_status == FocusStatus.active) return;
    _status = FocusStatus.active;
    _remainingSeconds = _durationMinutes * 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void cancelFocus() {
    _timer?.cancel();
    _timer = null;
    _status = FocusStatus.idle;
    _remainingSeconds = _durationMinutes * 60;
    notifyListeners();
  }

  void dismissCompleted() {
    _status = FocusStatus.idle;
    _remainingSeconds = _durationMinutes * 60;
    notifyListeners();
  }

  void _tick() {
    if (_remainingSeconds <= 1) {
      _timer?.cancel();
      _timer = null;
      _completedToday++;
      _prefs.setInt(_kCompleted, _completedToday);
      _status = FocusStatus.completed;
      _remainingSeconds = 0;
    } else {
      _remainingSeconds--;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
