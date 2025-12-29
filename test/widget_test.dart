import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:projet/providers/user_provider.dart';
import 'package:projet/screens/auth/onboarding_screen.dart';
import 'package:projet/screens/home/home_screen.dart';

void main() {
  testWidgets('Onboarding page displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    await tester.pump();

    expect(find.text('Med-Pass'), findsOneWidget);
    expect(find.text('Travel Light with Medpass'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Home screen displays welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.text('Your Medical Space'), findsOneWidget);
  });

  testWidgets('Home screen has drawer with menu items', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Billing Info'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
