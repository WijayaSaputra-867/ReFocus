import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/focus_notifier.dart';
import '../domain/protection_notifier.dart';
import '../theme.dart';

/// Focus Mode screen (Phase 4).
/// Full-screen modal — launched from HomeScreen.
/// Countdown timer with duration picker, start/cancel, completion state.
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusNotifier>();
    final protected = context.watch<ProtectionNotifier>().protectedApps.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: AppColors.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Focus Mode',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: switch (focus.status) {
          FocusStatus.completed => _CompletedView(focus: focus),
          _ => _MainView(focus: focus, protectedCount: protected),
        },
      ),
    );
  }
}

// ── Main view (idle + active) ─────────────────────────────────────────────────

class _MainView extends StatelessWidget {
  const _MainView({required this.focus, required this.protectedCount});
  final FocusNotifier focus;
  final int protectedCount;

  @override
  Widget build(BuildContext context) {
    final isActive = focus.isActive;
    final progress = isActive
        ? focus.remainingSeconds / (focus.durationMinutes * 60)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // ── Circular timer ───────────────────────────────────────────────
          _CircularTimer(
            progress: progress,
            remainingSeconds: isActive ? focus.remainingSeconds : null,
            durationMinutes: focus.durationMinutes,
            isActive: isActive,
          ),

          const SizedBox(height: 40),

          // ── Duration picker (hidden while active) ────────────────────────
          if (!isActive) _DurationPicker(focus: focus),
          if (isActive) const SizedBox(height: 56),

          const SizedBox(height: 32),

          // ── Protected apps note ──────────────────────────────────────────
          _PolicyNote(protectedCount: protectedCount),

          const Spacer(),

          // ── Start / Cancel ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: isActive
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentLocked,
                      side: BorderSide(
                        color: AppColors.accentLocked.withAlpha(80),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: focus.cancelFocus,
                    child: const Text('Cancel Focus'),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentCooldown,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: focus.startFocus,
                    child: const Text(
                      'Start Focus',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 8),

          // ── Today's completions ──────────────────────────────────────────
          Text(
            focus.completedToday == 0
                ? 'No focus sessions today yet'
                : '${focus.completedToday} session${focus.completedToday == 1 ? '' : 's'} completed today',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Circular timer ────────────────────────────────────────────────────────────

class _CircularTimer extends StatelessWidget {
  const _CircularTimer({
    required this.progress,
    required this.remainingSeconds,
    required this.durationMinutes,
    required this.isActive,
  });
  final double progress;
  final int? remainingSeconds;
  final int durationMinutes;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final label = remainingSeconds != null
        ? _fmt(remainingSeconds!)
        : '${durationMinutes}m';

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox.expand(
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                color: AppColors.accentCooldown,
                isActive: isActive,
              ),
            ),
          ),
          // Time text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                ),
              ),
              if (isActive)
                Text(
                  'remaining',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                )
              else
                Text(
                  'focus',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.isActive,
  });
  final double progress;
  final Color color;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    final strokeWidth = 6.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withAlpha(30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (!isActive) return;

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at top
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.isActive != isActive;
}

// ── Duration picker ───────────────────────────────────────────────────────────

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({required this.focus});
  final FocusNotifier focus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: FocusNotifier.availableMinutes.map((m) {
        final selected = focus.durationMinutes == m;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => focus.setDuration(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accentCooldown.withAlpha(30)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.accentCooldown
                      : Colors.transparent,
                ),
              ),
              child: Text(
                '${m}m',
                style: TextStyle(
                  color: selected
                      ? AppColors.accentCooldown
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Policy note ───────────────────────────────────────────────────────────────

class _PolicyNote extends StatelessWidget {
  const _PolicyNote({required this.protectedCount});
  final int protectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.accentIdle, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              protectedCount == 0
                  ? 'No apps are currently protected.'
                  : '$protectedCount protected app${protectedCount == 1 ? '' : 's'} will be monitored during focus.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completed view ────────────────────────────────────────────────────────────

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.focus});
  final FocusNotifier focus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.accentIdle,
          ),
          const SizedBox(height: 24),
          Text(
            'Focus complete!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You stayed focused for ${focus.durationMinutes} minutes.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${focus.completedToday} session${focus.completedToday == 1 ? '' : 's'} today',
            style: TextStyle(
              color: AppColors.accentIdle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentIdle,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: focus.dismissCompleted,
              child: const Text(
                'Start another',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Done',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
