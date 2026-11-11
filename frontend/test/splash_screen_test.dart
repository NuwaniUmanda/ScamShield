import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/screens/splash/splash_screen.dart';
import 'package:frontend/widgets/app_logo.dart';

void main() {
  testWidgets('Splash Screen renders logo, title, security label, tagline, and blue background', (WidgetTester tester) async {
    bool didNavigate = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          delay: const Duration(milliseconds: 500),
          onFinished: () {
            didNavigate = true;
          },
        ),
      ),
    );

    // 1. Logo
    expect(find.byType(ShieldLogoIcon), findsOneWidget);

    // 2. ScamShield Name
    expect(find.text('ScamShield'), findsOneWidget);

    // 3. AI + Blockchain Security
    expect(find.text('AI + Blockchain Security'), findsOneWidget);

    // 4. Tagline
    expect(find.text('Stay Safe, Stay Secure'), findsOneWidget);

    // 5. Blue Background
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.primary);

    // 6. Test navigation callback after delay
    expect(didNavigate, isFalse);
    await tester.pump(const Duration(milliseconds: 600));
    expect(didNavigate, isTrue);
  });
}
