import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/focus_notifier.dart';
import '../domain/protection_notifier.dart';
import '../theme.dart';

/// Stats screen — Phase 3: full local statistics.
/// Shows today's summary, weekly bar chart, and resisted sessions.
/// No external chart library needed; bars drawn with CustomPaint.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProtectionNotifier>();
    final focus = context.watch<FocusNotifier>();
    final snap = notifier.snap;
    final settings = notifier.settings;
    final weeklyLog = notifier.getWeeklyLog();
    final remaining = (settings.dailySessionLimit - snap.sessionsToday).clamp(
      0,
      99,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Statistics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Today ──────────────────────────────────────────────────────────
          _SectionLabel(text: 'Today'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  icon: Icons.timer_outlined,
                  color: AppColors.accentDistracting,
                  label: 'Distraction',
                  value: _fmtDuration(snap.totalDistractionSecondsToday),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigStat(
                  icon: Icons.repeat_outlined,
                  color: AppColors.accentIdle,
                  label: 'Sessions',
                  value: '${snap.sessionsToday}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  icon: Icons.hourglass_bottom_outlined,
                  color: AppColors.textSecondary,
                  label: 'Remaining',
                  value: '$remaining',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigStat(
                  icon: Icons.self_improvement_outlined,
                  color: AppColors.accentCooldown,
                  label: 'Resisted',
                  value: '${snap.resistedToday}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  icon: Icons.timer_outlined,
                  color: AppColors.accentCooldown,
                  label: 'Focus done',
                  value: '${focus.completedToday}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigStat(
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.textSecondary,
                  label: 'Focus preset',
                  value: '${focus.durationMinutes}m',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Weekly chart ───────────────────────────────────────────────────
          _SectionLabel(text: 'This week — distraction time'),
          const SizedBox(height: 16),
          weeklyLog.isEmpty ? _EmptyChart() : _WeeklyBarChart(log: weeklyLog),

          const SizedBox(height: 32),

          // ── Weekly summary table ───────────────────────────────────────────
          if (weeklyLog.isNotEmpty) ...[
            _SectionLabel(text: 'Daily breakdown'),
            const SizedBox(height: 12),
            ...weeklyLog.reversed.map((day) => _DayRow(day: day)),
          ],
        ],
      ),
    );
  }

  static String _fmtDuration(int s) {
    if (s == 0) return '0m';
    if (s < 60) return '${s}s';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
  );
}

// ── Big stat card ─────────────────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Weekly bar chart ──────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.log});
  final List<Map<String, dynamic>> log;

  @override
  Widget build(BuildContext context) {
    final maxSeconds = log
        .map((e) => (e['distractionSeconds'] as int? ?? 0))
        .fold(0, (a, b) => a > b ? a : b);

    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: log.map((day) {
                final secs = (day['distractionSeconds'] as int? ?? 0);
                final fraction = maxSeconds > 0 ? secs / maxSeconds : 0.0;
                final label = _shortDate(day['date'] as String? ?? '');
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (secs > 0)
                          Text(
                            _fmt(secs),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: (fraction * 72).clamp(4, 72),
                          decoration: BoxDecoration(
                            color: AppColors.accentDistracting.withAlpha(
                              fraction > 0 ? 200 : 50,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    // iso = YYYY-MM-DD
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    try {
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return days[dt.weekday];
    } catch (_) {
      return parts[2]; // just day number
    }
  }

  String _fmt(int s) {
    if (s < 60) return '${s}s';
    return '${s ~/ 60}m';
  }
}

// ── Empty chart placeholder ───────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Data will appear after your first distraction session.',
          style: TextStyle(
            color: AppColors.textSecondary.withAlpha(150),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Day row ───────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});
  final Map<String, dynamic> day;

  @override
  Widget build(BuildContext context) {
    final secs = day['distractionSeconds'] as int? ?? 0;
    final sessions = day['sessions'] as int? ?? 0;
    final resisted = day['resisted'] as int? ?? 0;
    final date = day['date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(date),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          _MiniStat(label: _fmtDuration(secs), icon: Icons.timer_outlined),
          const SizedBox(width: 12),
          _MiniStat(label: '$sessions sessions', icon: Icons.repeat_outlined),
          const SizedBox(width: 12),
          _MiniStat(
            label: '$resisted resisted',
            icon: Icons.self_improvement_outlined,
          ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${months[m]} ${parts[2]}';
  }

  String _fmtDuration(int s) {
    if (s == 0) return '0m';
    if (s < 60) return '${s}s';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
