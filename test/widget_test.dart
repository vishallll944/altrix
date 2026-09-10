import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:altrix/main.dart';
import 'package:altrix/features/auth/presentation/providers/auth_providers.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_auth_session_storage.dart';
import 'fakes/fake_push_notification_service.dart';
import 'fakes/patient_test_overrides.dart';
import 'package:altrix/features/notifications/presentation/providers/push_notification_provider.dart';

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
        pushNotificationServiceProvider.overrideWithValue(FakePushNotificationService()),
        ...patientTestOverrides(),
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

    expect(find.text('Join Zoom'), findsAtLeast(1));
    expect(find.text('Quick actions'), findsOneWidget);
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

    expect(find.text('Join Zoom'), findsAtLeast(1));

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('All your appointments'), findsOneWidget);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Maya Patel'), findsWidgets);
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets("Today's Wellness sheet opens and displays all fields", (tester) async {
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

    // Tap Check in in Quick Actions
    final checkInFinder = find.text('Check in');
    await tester.ensureVisible(checkInFinder);
    await tester.pumpAndSettle();
    await tester.tap(checkInFinder);
    await tester.pumpAndSettle();

    expect(find.text("Today's Wellness"), findsWidgets);
    expect(find.text('8/10'), findsOneWidget);
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('7 hrs'), findsOneWidget);
    expect(find.text('Feeling much better today and rested well.'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });
}
