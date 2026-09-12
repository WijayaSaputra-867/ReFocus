import 'package:flutter/material.dart';
import '../services/platform_service.dart';
import '../theme.dart';

/// Permission status screen (Phase 2).
/// Shows usage-stats permission and battery optimization status,
/// with one-tap actions to open the relevant Android settings page.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _hasUsage = false;
  bool _hasBattery = false;
  bool _hasOverlay = false;
  bool _hasNotification = false;
  bool _hasAccessibility = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check after user returns from the Settings app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final usage = await PlatformService.hasUsagePermission();
    final battery = await PlatformService.hasBatteryOptimizationIgnored();
    final overlay = await PlatformService.hasOverlayPermission();
    final notif = await PlatformService.hasNotificationPermission();
    final accessibility = await PlatformService.hasAccessibilityPermission();
    if (mounted) {
      setState(() {
        _hasUsage = usage;
        _hasBattery = battery;
        _hasOverlay = overlay;
        _hasNotification = notif;
        _hasAccessibility = accessibility;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Permissions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status',
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.accentIdle),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _SectionHeader(text: 'Required'),
                const SizedBox(height: 12),
                _PermissionCard(
                  icon: Icons.bar_chart_outlined,
                  title: 'Usage Access',
                  description:
                      'Lets Refocus see which app is in the foreground so it can '
                      'track time spent in distracting apps. '
                      'No data leaves your device.',
                  granted: _hasUsage,
                  onFix: () async {
                    await PlatformService.requestUsagePermission();
                  },
                ),
                const SizedBox(height: 12),
                _PermissionCard(
                  icon: Icons.layers_outlined,
                  title: 'Display Over Other Apps',
                  description:
                      'Displays the 5-second countdown blocker over distracting apps '
                      'when your session ends or cooldown is active, then closes them.',
                  granted: _hasOverlay,
                  onFix: () async {
                    await PlatformService.requestOverlayPermission();
                  },
                  onTest: () async {
                    final shown = await PlatformService.showOverlayBlocker(
                      title: 'Refocus Blocker Test',
                      message: 'Overlay blocker aktif dan berfungsi normal!',
                      seconds: 5,
                    );
                    if (!shown && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gagal menampilkan blocker. Periksa izin overlay di pengaturan.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _PermissionCard(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  description:
                      'Sends heads-up alert notifications when your social media session time is up '
                      'and keeps background protection alive.',
                  granted: _hasNotification,
                  onFix: () async {
                    await PlatformService.requestNotificationPermission();
                  },
                ),
                const SizedBox(height: 12),
                _PermissionCard(
                  icon: Icons.battery_charging_full_outlined,
                  title: 'Unrestricted Battery',
                  description:
                      'Prevents Android from killing Refocus in the background. '
                      'Without this, the protection engine may stop after the '
                      'screen turns off.',
                  granted: _hasBattery,
                  onFix: () async {
                    await PlatformService.requestIgnoreBatteryOptimization();
                  },
                ),
                const SizedBox(height: 12),
                _PermissionCard(
                  icon: Icons.accessibility_new_outlined,
                  title: 'Accessibility Service (Instant Detection)',
                  description:
                      'Provides instant 0-second detection when opening distraction apps and enforces blocking immediately without OS delays.',
                  granted: _hasAccessibility,
                  onFix: () async {
                    await PlatformService.requestAccessibilityPermission();
                  },
                ),
                const SizedBox(height: 32),
                _SectionHeader(text: 'Privacy commitment'),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.lock_outline,
                  text:
                      'Refocus is fully local-first. Permission data, usage '
                      'statistics, and app lists never leave your device. '
                      'There are no accounts, no analytics, and no cloud sync.',
                ),
              ],
            ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Permission card ───────────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.onFix,
    this.onTest,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onFix;
  final VoidCallback? onTest;

  @override
  Widget build(BuildContext context) {
    final accent = granted ? AppColors.accentIdle : AppColors.accentDistracting;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusBadge(granted: granted),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (!granted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentIdle.withAlpha(30),
                  foregroundColor: AppColors.accentIdle,
                  side: BorderSide(color: AppColors.accentIdle.withAlpha(80)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onFix,
                child: const Text('Open Settings'),
              ),
            ),
          ] else if (onTest != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentIdle,
                  side: BorderSide(color: AppColors.accentIdle.withAlpha(80)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                onPressed: onTest,
                label: const Text('Test Blocker'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.granted});
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final color = granted ? AppColors.accentIdle : AppColors.accentDistracting;
    final label = granted ? 'Granted' : 'Missing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentIdle, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
