import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:altrix/main.dart';
import 'package:altrix/features/auth/presentation/providers/auth_providers.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_auth_session_storage.dart';

void main() {
  late FakeAuthSessionStorage fakeSessionStorage;

  Future<void> setPhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Widget testApp() {
    fakeSessionStorage = FakeAuthSessionStorage();
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        authSessionStorageProvider.overrideWithValue(fakeSessionStorage),
      ],
      child: const AltrixApp(),
    );
  }

  Future<void> pumpPastSplash(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
  }

  testWidgets('Sign in screen renders', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(testApp());
    await pumpPastSplash(tester);

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Your care, in one place'), findsOneWidget);
  });

  testWidgets('Sign in opens the home screen', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(testApp());
    await pumpPastSplash(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'maya@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Join Zoom'), findsOneWidget);
    expect(find.text('How are you today?'), findsOneWidget);
    expect(find.text('From your care team'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Upcoming'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Upcoming'), findsOneWidget);
  });

  testWidgets('Home tabs and check-in are usable', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(testApp());
    await pumpPastSplash(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'maya@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

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
