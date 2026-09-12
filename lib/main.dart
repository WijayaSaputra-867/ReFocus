import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'domain/focus_notifier.dart';
import 'domain/protection_notifier.dart';
import 'screens/apps_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/stats_screen.dart';
import 'services/advanced_features_service.dart';
import 'services/translation_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final Future<List<dynamic>> _init;

  @override
  void initState() {
    super.initState();
    _init = Future.wait([
      ProtectionNotifier.create(),
      FocusNotifier.create(),
      TranslationService.create(),
      AdvancedFeaturesService.create(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _init,
      builder: (context, snap) {
        if (!snap.hasData) {
          // Instant dark frame — no black screen gap
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            home: const Scaffold(backgroundColor: AppColors.background),
          );
        }
        final r = snap.data!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: r[0] as ProtectionNotifier),
            ChangeNotifierProvider.value(value: r[1] as FocusNotifier),
            ChangeNotifierProvider.value(value: r[2] as TranslationService),
            ChangeNotifierProvider.value(value: r[3] as AdvancedFeaturesService),
          ],
          child: const RefocusApp(),
        );
      },
    );
  }
}

class RefocusApp extends StatelessWidget {
  const RefocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingCompleted = context
        .watch<ProtectionNotifier>()
        .onboardingCompleted;

    return MaterialApp(
      title: 'Refocus',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: onboardingCompleted ? const _Shell() : const OnboardingScreen(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with WidgetsBindingObserver {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ProtectionNotifier>().reloadFromStorage();
    }
  }

  static const _screens = [
    HomeScreen(),
    AppsScreen(),
    RulesScreen(),
    StatsScreen(),
    PermissionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentIdle.withAlpha(40),
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Apps',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Rules',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Permissions',
          ),
        ],
      ),
    );
  }
}
