import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/focus_notifier.dart';
import '../domain/protection_notifier.dart';
import '../domain/protection_state.dart';
import '../screens/focus_screen.dart';
import '../services/platform_service.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProtectionNotifier>();
    final snap = notifier.snap;
    final settings = notifier.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/branding/refocus-app-icon.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refocus',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Take back your attention.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Permission warning banner (if permissions missing) ─────────
              FutureBuilder<bool>(
                future: PlatformService.hasUsagePermission().then(
                  (u) async => u && await PlatformService.hasOverlayPermission(),
                ),
                builder: (context, permSnap) {
                  if (permSnap.connectionState == ConnectionState.done &&
                      permSnap.data == false) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: AppColors.accentCooldown,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Izin Diperlukan',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Akses Penggunaan & Tampilkan di Atas Aplikasi Lain dibutuhkan agar blocker aktif.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (!await PlatformService.hasUsagePermission()) {
                                await PlatformService.requestUsagePermission();
                              } else if (!await PlatformService.hasOverlayPermission()) {
                                await PlatformService.requestOverlayPermission();
                              }
                            },
                            child: Text(
                              'Beri Izin',
                              style: TextStyle(
                                color: AppColors.accentCooldown,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // ── Status card ────────────────────────────────────────────────
              _StatusCard(snap: snap, settings: settings),

              const SizedBox(height: 20),

              // ── Session row ──────────────────────────────────────────────────
              _SessionRow(snap: snap, settings: settings),

              const SizedBox(height: 32),

              // ── Focus button ────────────────────────────────────────────────
              _FocusButton(),

              const SizedBox(height: 32),

              // ── Toggle ─────────────────────────────────────────────────────
              _ProtectionToggle(
                enabled: snap.protectionEnabled,
                onToggle: notifier.toggleProtection,
              ),

              const SizedBox(height: 16),

              // ── Dev helper (cycles states for UI preview) ──────────────────
              // ponytail: remove when platform channel is wired
              if (kDebugMode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        if (snap.status == ProtectionStatus.distracting) {
                          notifier.onAppBackgrounded();
                        } else {
                          notifier.onAppForegrounded('TikTok');
                        }
                      },
                      child: Text(
                        snap.status == ProtectionStatus.distracting
                            ? 'DEV: Exit app'
                            : 'DEV: Open TikTok',
                        style: TextStyle(
                          color: AppColors.accentIdle,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: notifier.debugAdvanceState,
                      child: Text(
                        'Cycle (${snap.status.name})',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => PlatformService.showOverlayBlocker(
                        title: 'Refocus Blocker Test',
                        message: 'Ini adalah preview blocker saat batas waktu aplikasi tercapai.',
                        seconds: 5,
                      ),
                      child: Text(
                        'Test Blocker',
                        style: TextStyle(
                          color: AppColors.accentDistracting,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snap, required this.settings});
  final ProtectionSnapshot snap;
  final ProtectionSettings settings;

  @override
  Widget build(BuildContext context) {
    final (icon, label, sub, accent) = _content(snap, settings);
    final subMessage = _subMessage(snap, settings);
    final cooldownProgress =
        snap.status == ProtectionStatus.cooldown && settings.cooldownSeconds > 0
        ? 1.0 -
              (snap.cooldownRemainingSeconds / settings.cooldownSeconds).clamp(
                0.0,
                1.0,
              )
        : null;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withAlpha(60), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accent,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (cooldownProgress != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    sub,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: cooldownProgress,
                        color: accent,
                        backgroundColor: accent.withAlpha(30),
                        strokeWidth: 4,
                      ),
                      Icon(Icons.hourglass_top, color: accent, size: 18),
                    ],
                  ),
                ),
              ],
            )
          else
            Text(
              sub,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w300,
                letterSpacing: -1,
              ),
            ),
          if (subMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              subMessage,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, String, String, Color) _content(
    ProtectionSnapshot s,
    ProtectionSettings cfg,
  ) {
    switch (s.status) {
      case ProtectionStatus.idle:
        if (s.elapsedSeconds > 0) {
          final mm = (s.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
          final ss = (s.elapsedSeconds % 60).toString().padLeft(2, '0');
          return (
            Icons.pause_circle_outline,
            'SESI DIJEDA',
            '$mm:$ss',
            AppColors.accentDistracting,
          );
        }
        return (
          Icons.shield_outlined,
          s.protectionEnabled ? 'PROTECTION ON' : 'PROTECTION OFF',
          s.protectionEnabled ? 'All clear' : 'Tap below to enable protection',
          s.protectionEnabled ? AppColors.accentIdle : AppColors.textSecondary,
        );
      case ProtectionStatus.distracting:
        final mm = (s.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
        final ss = (s.elapsedSeconds % 60).toString().padLeft(2, '0');
        return (
          Icons.timer_outlined,
          'DISTRACTING',
          '$mm:$ss',
          AppColors.accentDistracting,
        );
      case ProtectionStatus.cooldown:
        final mm = (s.cooldownRemainingSeconds ~/ 60).toString().padLeft(
          2,
          '0',
        );
        final ss = (s.cooldownRemainingSeconds % 60).toString().padLeft(2, '0');
        return (
          Icons.hourglass_top_outlined,
          'COOLING DOWN',
          '$mm:$ss',
          AppColors.accentCooldown,
        );
      case ProtectionStatus.dailyLocked:
        return (
          Icons.lock_outline,
          'DAILY LIMIT REACHED',
          'Resets at midnight',
          AppColors.accentLocked,
        );
    }
  }

  String? _subMessage(ProtectionSnapshot s, ProtectionSettings cfg) {
    switch (s.status) {
      case ProtectionStatus.idle:
        if (s.elapsedSeconds > 0) {
          final rem = (cfg.triggerSeconds - s.elapsedSeconds).clamp(0, cfg.triggerSeconds);
          final mm = rem ~/ 60;
          final ss = rem % 60;
          return 'Sesi dijeda • Sisa jatah: ${(mm).toString().padLeft(2, '0')}:${(ss).toString().padLeft(2, '0')}';
        }
        return null;
      case ProtectionStatus.distracting:
        final remaining = cfg.triggerSeconds - s.elapsedSeconds;
        if (remaining <= 60) {
          return 'Cooldown starts in under a minute…';
        }
        final mm = remaining ~/ 60;
        return '$mm min until cooldown kicks in.';
      case ProtectionStatus.cooldown:
        return 'Take a breath. Refocus. The urge will pass.';
      case ProtectionStatus.dailyLocked:
        return "You've hit today's limit. Great job resisting — see you tomorrow.";
    }
  }
}

// ── Session row ───────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.snap, required this.settings});
  final ProtectionSnapshot snap;
  final ProtectionSettings settings;

  @override
  Widget build(BuildContext context) {
    final used = snap.sessionsToday;
    final limit = settings.dailySessionLimit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat_outlined, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 12),
          Text(
            'Sessions today',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            '$used / $limit',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle ────────────────────────────────────────────────────────────────────

class _ProtectionToggle extends StatelessWidget {
  const _ProtectionToggle({required this.enabled, required this.onToggle});
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.accentIdle.withAlpha(26)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? AppColors.accentIdle.withAlpha(100)
                : AppColors.textSecondary.withAlpha(50),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              enabled ? Icons.shield : Icons.shield_outlined,
              color: enabled ? AppColors.accentIdle : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              enabled ? 'Protection enabled' : 'Protection disabled',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: enabled ? AppColors.accentIdle : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Focus button ──────────────────────────────────────────────────────────────

class _FocusButton extends StatelessWidget {
  const _FocusButton();

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusNotifier>();
    final isActive = focus.isActive;
    final color = isActive ? AppColors.accentCooldown : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const FocusScreen(),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentCooldown.withAlpha(20)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.accentCooldown.withAlpha(100)
                : AppColors.textSecondary.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.self_improvement_outlined, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isActive
                    ? 'Focus in progress — tap to view'
                    : 'Start a focus session',
                style: TextStyle(color: color, fontSize: 14),
              ),
            ),
            if (isActive)
              Text(
                _fmt(focus.remainingSeconds),
                style: TextStyle(
                  color: AppColors.accentCooldown,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              )
            else
              Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }
}
