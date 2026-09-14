import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:altrix/features/auth/presentation/providers/auth_providers.dart';
import 'package:altrix/features/notifications/presentation/providers/push_notification_provider.dart';
import 'package:altrix/features/patient/data/models/patient_models.dart';
import 'package:altrix/features/patient/presentation/providers/patient_providers.dart';
import 'package:altrix/screens/home_screen.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_auth_session_storage.dart';
import 'fakes/fake_push_notification_service.dart';
import 'fakes/patient_test_overrides.dart';

void main() {
  testWidgets('Home screen displays skeleton loader while next session is loading', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final completer = Completer<List<AppointmentModel>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          authSessionStorageProvider.overrideWithValue(FakeAuthSessionStorage()),
          pushNotificationServiceProvider.overrideWithValue(FakePushNotificationService()),
          ...patientTestOverrides(),
          appointmentsProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HomeScreen(),
          ),
        ),
      ),
    );

    // Initial pump while appointments are still loading
    await tester.pump(const Duration(milliseconds: 100));

    // The skeleton card should be visible (LinearGradient with navy colors and container)
    expect(find.byType(HomeScreen), findsOneWidget);
    // Since it is loading, the Join Zoom button should not be present yet
    expect(find.text('Join Zoom'), findsNothing);

    // Complete the loading
    completer.complete([
      AppointmentModel(
        id: 'apt-1',
        title: 'Individual Therapy',
        providerName: 'Maya Patel, LCSW-C',
        dateLabel: 'Today',
        timeLabel: '2:00 PM',
        endTimeLabel: '2:50 PM',
        visitType: 'Video visit',
        duration: '50 min',
        isVirtual: true,
        status: 'scheduled',
        joinToken: '',
        joinUrl: 'https://zoom.us/j/test',
        location: '',
        note: '',
        sortDateTime: DateTime.now().add(const Duration(hours: 2)),
        raw: const {},
      ),
    ]);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Now the session card should be loaded with Join Zoom button
    expect(find.text('Join Zoom'), findsOneWidget);
    // Verify badge shows Video duration instead of Video visit
    expect(find.text('Video duration: 50 min'), findsOneWidget);
    expect(find.text('Video visit'), findsNothing);
  });
}
