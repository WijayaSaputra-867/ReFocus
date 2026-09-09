import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../domain/protection_notifier.dart';
import '../domain/protection_state.dart';
import '../services/advanced_features_service.dart';
import '../services/backup_service.dart';
import '../services/translation_service.dart';
import '../theme.dart';

/// Rules screen: configure trigger, daily limit, cooldown, language, and advanced features.
/// PRD FR-02, FR-03; ROADMAP Phase 1, Phase 5 (Community/i18n), Phase 6 (Advanced Features).
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  late ProtectionSettings _draft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _draft = context.read<ProtectionNotifier>().settings;
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<TranslationService>();
    final advanced = context.watch<AdvancedFeaturesService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          tr.t('rules'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _RuleSlider(
            label: tr.t('trigger_duration'),
            sublabel: _fmtMinutes(_draft.triggerSeconds),
            value: _draft.triggerSeconds.toDouble(),
            min: 60,
            max: 60 * 60,
            divisions: 59,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(triggerSeconds: v.round()),
            ),
          ),
          const SizedBox(height: 24),
          _RuleSlider(
            label: tr.t('daily_limit'),
            sublabel: '${_draft.dailySessionLimit} sessions',
            value: _draft.dailySessionLimit.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(dailySessionLimit: v.round()),
            ),
          ),
          const SizedBox(height: 24),
          _RuleSlider(
            label: tr.t('cooldown_duration'),
            sublabel: _fmtMinutes(_draft.cooldownSeconds),
            value: _draft.cooldownSeconds.toDouble(),
            min: 60,
            max: 60 * 60,
            divisions: 59,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(cooldownSeconds: v.round()),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentIdle,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              context.read<ProtectionNotifier>().updateSettings(_draft);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr.t('rules_saved')),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
            child: Text(
              tr.t('save_rules'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 36),
          Text(
            'Preferences & Advanced',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // ── Language Selector (Phase 5) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, size: 20, color: AppColors.accentIdle),
                    const SizedBox(width: 12),
                    Text(
                      tr.t('language'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: tr.locale,
                  dropdownColor: AppColors.surface,
                  underline: const SizedBox.shrink(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                  style: TextStyle(
                    color: AppColors.accentIdle,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(
                      value: 'id',
                      child: Text('Bahasa Indonesia'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) tr.setLocale(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Encrypted Backup & Restore (Phase 6) ──
          _SettingsTile(
            icon: Icons.security,
            title: 'Encrypted Backup & Restore',
            subtitle: 'Local-first encrypted export and restore',
            onTap: () => _showBackupDialog(context),
          ),

          const SizedBox(height: 12),

          // ── Website Blocking (Phase 6) ──
          _SettingsTile(
            icon: Icons.block,
            title: 'Website Blocking',
            subtitle: '${advanced.blockedWebsites.length} domains in blocklist',
            onTap: () => _showWebsiteBlockingDialog(context, advanced),
          ),

          const SizedBox(height: 12),

          // ── Category Rules (Phase 6) ──
          _SettingsTile(
            icon: Icons.category_outlined,
            title: 'Category Rules',
            subtitle:
                'Social (${advanced.categoryRules['Social']! ~/ 60}m), Games (${advanced.categoryRules['Games']! ~/ 60}m)',
            onTap: () => _showCategoryDialog(context, advanced),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Encrypted Backup',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your data stays 100% on your device. Export or import an encrypted backup with a local passphrase.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Passphrase',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (passCtrl.text.trim().isEmpty) return;
              final backup = await BackupService.createEncryptedBackup(
                passCtrl.text.trim(),
              );
              await Clipboard.setData(ClipboardData(text: backup));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Encrypted backup copied to clipboard!',
                    ),
                    backgroundColor: AppColors.surface,
                  ),
                );
              }
            },
            child: Text(
              'Export',
              style: TextStyle(color: AppColors.accentIdle),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (passCtrl.text.trim().isEmpty) return;
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text == null) return;
              final ok = await BackupService.restoreFromBackup(
                data!.text!,
                passCtrl.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Backup restored successfully!'
                          : 'Failed to restore: invalid passphrase or data.',
                    ),
                    backgroundColor: AppColors.surface,
                  ),
                );
              }
            },
            child: Text(
              'Restore from Clip',
              style: TextStyle(color: AppColors.accentDistracting),
            ),
          ),
        ],
      ),
    );
  }

  void _showWebsiteBlockingDialog(
    BuildContext context,
    AdvancedFeaturesService service,
  ) {
    final siteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Blocked Websites',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: siteCtrl,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. twitter.com',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withAlpha(120),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: AppColors.accentIdle),
                      onPressed: () async {
                        if (siteCtrl.text.trim().isNotEmpty) {
                          await service.addBlockedWebsite(siteCtrl.text.trim());
                          siteCtrl.clear();
                          setDlgState(() {});
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    itemCount: service.blockedWebsites.length,
                    itemBuilder: (_, i) {
                      final domain = service.blockedWebsites[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          domain,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.accentDistracting,
                          ),
                          onPressed: () async {
                            await service.removeBlockedWebsite(domain);
                            setDlgState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    AdvancedFeaturesService service,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Per-Category Rules',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: service.categoryRules.entries.map((entry) {
            final mins = entry.value ~/ 60;
            return ListTile(
              title: Text(
                entry.key,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              trailing: DropdownButton<int>(
                value: mins,
                dropdownColor: AppColors.surface,
                underline: const SizedBox.shrink(),
                style: TextStyle(color: AppColors.accentIdle),
                items: [10, 15, 20, 30, 45, 60]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m m')))
                    .toList(),
                onChanged: (newMins) {
                  if (newMins != null) {
                    service.setCategoryLimit(entry.key, newMins * 60);
                    Navigator.pop(ctx);
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMinutes(int seconds) {
    final m = seconds ~/ 60;
    return m == 1 ? '1 minute' : '$m minutes';
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accentIdle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _RuleSlider extends StatelessWidget {
  const _RuleSlider({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String sublabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentIdle,
              thumbColor: AppColors.accentIdle,
              inactiveTrackColor: AppColors.accentIdle.withAlpha(40),
              overlayColor: AppColors.accentIdle.withAlpha(30),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
