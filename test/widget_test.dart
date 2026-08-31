import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:altrix/main.dart';
import 'package:altrix/screens/main_shell.dart';

void main() {
  Future<void> setPhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('Sign in screen renders and opens sign up', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const AltrixApp());

    expect(find.text('Altrixs'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Your care, in one place'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsWidgets);
    expect(find.text('Full name'), findsOneWidget);
  });

  testWidgets('Sign in opens the home screen', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const AltrixApp());

    await tester.enterText(
      find.byType(TextFormField).first,
      'maya@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Join Zoom'), findsOneWidget);
    expect(find.text('How are you today?'), findsOneWidget);
    expect(find.text('From your care team'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
  });

  testWidgets('Home tabs and check-in are usable', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(home: MainShell()),
    );

    expect(find.text('Join Zoom'), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Check-in saved'), findsOneWidget);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Upcoming visits with your care team'), findsOneWidget);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Maya Patel'), findsWidgets);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
