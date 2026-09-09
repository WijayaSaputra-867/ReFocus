import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/protection_notifier.dart';
import '../services/platform_service.dart';
import '../theme.dart';

/// Protected Apps screen: select and toggle protected apps (PRD FR-01).
/// Queries real installed applications from Android via PlatformService,
/// with fallback presets for testing/development.
class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<AppInfo> _installedApps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInstalledApps();
  }

  Future<void> _fetchInstalledApps() async {
    setState(() => _loading = true);
    final apps = await PlatformService.getInstalledApps();
    if (mounted) {
      setState(() {
        _installedApps = apps;
        _loading = false;
      });
    }
  }

  void _showAddAppDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add Protected App',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Netflix or package name',
            hintStyle: TextStyle(color: AppColors.textSecondary.withAlpha(150)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.textSecondary.withAlpha(100),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentIdle),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentIdle,
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<ProtectionNotifier>().toggleApp(name);
              }
              Navigator.pop(ctx);
            },
            child: Text('Add', style: TextStyle(color: AppColors.background)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProtectionNotifier>();
    final protectedApps = notifier.protectedApps;

    // Use native installed apps; fall back to manually-protected apps list
    // so users can still manage what's protected before granting permission.
    final List<({String title, String subtitle, String key})> items;
    if (_installedApps.isNotEmpty) {
      items = _installedApps.map((a) {
        return (title: a.appName, subtitle: a.packageName, key: a.packageName);
      }).toList();
    } else {
      items = protectedApps.map((name) {
        return (title: name, subtitle: 'Manually added', key: name);
      }).toList();
    }
    final bool isEmpty = items.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Protected Apps',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh installed apps',
            onPressed: _fetchInstalledApps,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add custom app',
            onPressed: () => _showAddAppDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Selected apps count toward your distraction timer across all switches.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentIdle,
                    ),
                  )
                : isEmpty
                ? _EmptyState(onRetry: _fetchInstalledApps)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // Match either package name or display name in protected set
                      final isProtected =
                          notifier.isAppProtected(item.key) ||
                          notifier.isAppProtected(item.title);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: SwitchListTile(
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              item.subtitle,
                              style: TextStyle(
                                color: AppColors.textSecondary.withAlpha(180),
                                fontSize: 12,
                              ),
                            ),
                            value: isProtected,
                            activeThumbColor: AppColors.accentIdle,
                            inactiveTrackColor: AppColors.surface,
                            onChanged: (_) {
                              // Toggle key (package name if available, else title)
                              notifier.toggleApp(item.key);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${protectedApps.length} apps currently protected.',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(150),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps_outlined,
              size: 56,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 20),
            Text(
              'No apps found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usage Access permission is required to list installed apps. '
              'Grant it in the Permissions tab, then tap Refresh.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentIdle,
                side: BorderSide(color: AppColors.accentIdle.withAlpha(100)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
