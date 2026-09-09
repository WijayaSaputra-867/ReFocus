/// The four states of the distraction engine.
/// Matches ARCHITECTURE.md §4 exactly.
enum ProtectionStatus { idle, distracting, cooldown, dailyLocked }

/// Immutable snapshot of user-configured rules.
class ProtectionSettings {
  const ProtectionSettings({
    this.triggerSeconds = 5 * 60,
    this.dailySessionLimit = 5,
    this.cooldownSeconds = 15 * 60,
  });

  final int triggerSeconds; // default 5 min
  final int dailySessionLimit; // default 5 sessions
  final int cooldownSeconds; // default 15 min

  ProtectionSettings copyWith({
    int? triggerSeconds,
    int? dailySessionLimit,
    int? cooldownSeconds,
  }) => ProtectionSettings(
    triggerSeconds: triggerSeconds ?? this.triggerSeconds,
    dailySessionLimit: dailySessionLimit ?? this.dailySessionLimit,
    cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
  );
}

/// Immutable snapshot of daily runtime state.
class ProtectionSnapshot {
  const ProtectionSnapshot({
    this.status = ProtectionStatus.idle,
    this.elapsedSeconds = 0,
    this.sessionsToday = 0,
    this.cooldownRemainingSeconds = 0,
    this.protectionEnabled = true,
    this.totalDistractionSecondsToday = 0,
    this.resistedToday = 0,
  });

  final ProtectionStatus status;
  final int elapsedSeconds; // current session timer
  final int sessionsToday;
  final int cooldownRemainingSeconds;
  final bool protectionEnabled;
  final int
  totalDistractionSecondsToday; // accumulated across all sessions today
  final int
  resistedToday; // cooldowns completed without re-entering protected app

  ProtectionSnapshot copyWith({
    ProtectionStatus? status,
    int? elapsedSeconds,
    int? sessionsToday,
    int? cooldownRemainingSeconds,
    bool? protectionEnabled,
    int? totalDistractionSecondsToday,
    int? resistedToday,
  }) => ProtectionSnapshot(
    status: status ?? this.status,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    sessionsToday: sessionsToday ?? this.sessionsToday,
    cooldownRemainingSeconds:
        cooldownRemainingSeconds ?? this.cooldownRemainingSeconds,
    protectionEnabled: protectionEnabled ?? this.protectionEnabled,
    totalDistractionSecondsToday:
        totalDistractionSecondsToday ?? this.totalDistractionSecondsToday,
    resistedToday: resistedToday ?? this.resistedToday,
  );
}
