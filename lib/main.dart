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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final protection = await ProtectionNotifier.create();
  final focus = await FocusNotifier.create();
  final translation = await TranslationService.create();
  final advanced = await AdvancedFeaturesService.create();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: protection),
        ChangeNotifierProvider.value(value: focus),
        ChangeNotifierProvider.value(value: translation),
        ChangeNotifierProvider.value(value: advanced),
      ],
      child: const RefocusApp(),
    ),
  );
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

class _ShellState extends State<_Shell> {
  int _idx = 0;

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
