import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:refocus/domain/focus_notifier.dart';
import 'package:refocus/domain/protection_notifier.dart';
import 'package:refocus/main.dart';
import 'package:refocus/services/advanced_features_service.dart';
import 'package:refocus/services/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'RefocusApp first launch shows onboarding and navigates to home',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final notifier = await ProtectionNotifier.create();
      final focusNotifier = await FocusNotifier.create();
      final translation = await TranslationService.create();
      final advanced = await AdvancedFeaturesService.create();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: notifier),
            ChangeNotifierProvider.value(value: focusNotifier),
            ChangeNotifierProvider.value(value: translation),
            ChangeNotifierProvider.value(value: advanced),
          ],
          child: const RefocusApp(),
        ),
      );

      // Initial state: Onboarding is visible
      expect(find.text('Take back your attention.'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Tap Skip -> Navigates to main Home shell
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Refocus'), findsOneWidget);
      expect(find.text('PROTECTION OFF'), findsOneWidget);

      notifier.dispose();
      focusNotifier.dispose();
    },
  );
}
