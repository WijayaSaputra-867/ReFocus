import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/protection_notifier.dart';
import '../services/platform_service.dart';
import '../theme.dart';

/// Onboarding screen: 3-step product intro, privacy statement, and permission setup.
/// PRD §10, §11 & PRODUCT.md Brand Commitments.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _steps = [
    _OnboardingStep(
      icon: Icons.filter_center_focus_rounded,
      showLogo: true,
      badge: 'CONCEPT',
      title: 'Take back your attention.',
      subtitle:
          'Switching between TikTok, Instagram, and games bypasses per-app timers. Refocus counts your distraction globally as one continuous session.',
      highlight:
          'Continuous distraction timer · Controlled friction · You set the rules',
    ),
    _OnboardingStep(
      icon: Icons.shield_outlined,
      badge: 'PRIVACY FIRST',
      title: 'Your data stays on your device.',
      subtitle:
          'Refocus requires no account, uses no cloud servers, has no analytics, and contains no ads. 100% local-first and open-source.',
      highlight: 'Zero telemetry · Offline by design · Fully auditable code',
    ),
    _OnboardingStep(
      icon: Icons.lock_clock_outlined,
      badge: 'TRANSPARENT PERMISSIONS',
      title: 'Permissions explained plainly.',
      subtitle:
          'Tap "Grant Permissions" to set up Usage Access, Overlay, and Battery Optimization — all required for Refocus to work properly.',
      highlight:
          'Reads: foreground package name only.\nNever reads: messages, passwords, or screen contents.',
      showPermissionButton: true,
    ),
  ];

  Future<void> _next() async {
    if (_currentPage < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      // Request all missing permissions sequentially before finishing onboarding
      if (!await PlatformService.hasUsagePermission()) {
        await PlatformService.requestUsagePermission();
      }
      if (!await PlatformService.hasOverlayPermission()) {
        await PlatformService.requestOverlayPermission();
      }
      if (!await PlatformService.hasBatteryOptimizationIgnored()) {
        await PlatformService.requestIgnoreBatteryOptimization();
      }
      if (mounted) context.read<ProtectionNotifier>().completeOnboarding();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextButton(
                  onPressed: () =>
                      context.read<ProtectionNotifier>().completeOnboarding(),
                  child: Text(
                    isLast ? '' : 'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

            // Main pager
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final step = _steps[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        step.showLogo
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/branding/refocus-app-icon.png',
                                  width: 64,
                                  height: 64,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.accentIdle.withAlpha(50),
                                  ),
                                ),
                                child: Icon(
                                  step.icon,
                                  size: 32,
                                  color: AppColors.accentIdle,
                                ),
                              ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentIdle.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            step.badge,
                            style: TextStyle(
                              color: AppColors.accentIdle,
                              fontSize: 11,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            step.highlight,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        if (step.showPermissionButton) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accentIdle,
                              side: BorderSide(
                                color: AppColors.accentIdle.withAlpha(120),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.security, size: 18),
                            label: const Text('Grant Permissions'),
                            onPressed: _next,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Row(
                children: [
                  // Page indicator dots
                  Row(
                    children: List.generate(
                      _steps.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.accentIdle
                              : AppColors.textSecondary.withAlpha(60),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Action button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentIdle,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _next,
                    child: Text(
                      isLast ? 'Get Started' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.highlight,
    this.showLogo = false,
    this.showPermissionButton = false,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final String highlight;
  final bool showLogo;
  final bool showPermissionButton;
}
