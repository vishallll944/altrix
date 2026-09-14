import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:altrix/features/help/presentation/screens/help_center_screen.dart';
import 'package:altrix/features/patient/data/models/patient_models.dart';
import 'package:altrix/features/patient/presentation/providers/patient_providers.dart';
import 'package:altrix/features/patient/presentation/screens/appointment_editor_screen.dart';
import 'package:altrix/features/resources/presentation/screens/resources_screen.dart';
import 'package:altrix/features/telehealth/presentation/screens/telehealth_room_screen.dart';

void main() {
  testWidgets('HelpCenterScreen renders hero, search, contact options, and FAQs',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: HelpCenterScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('How can we help you today?'), findsOneWidget);
    expect(find.text('Support Ticket'), findsOneWidget);
    expect(find.text('Call Clinic'), findsOneWidget);
    expect(find.text('Email Us'), findsOneWidget);
    expect(find.text('Frequently Asked Questions'), findsOneWidget);

    // Expand first FAQ
    final firstFaq = find.text('How do I join my virtual telehealth video visit?');
    expect(firstFaq, findsOneWidget);
    await tester.tap(firstFaq);
    await tester.pumpAndSettle();

    expect(find.textContaining('Telehealth Lobby'), findsOneWidget);

    // Open Contact Support modal
    await tester.tap(find.text('Support Ticket'));
    await tester.pumpAndSettle();
    expect(find.text('Contact Clinic Support'), findsOneWidget);
    expect(find.text('Submit Ticket'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('ResourcesScreen renders Health Library, Forms tab, and Crisis Hotlines',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockForms = [
      PatientFormModel.fromJson(const {
        'id': 'form-123',
        'title': 'Telehealth Intake Questionnaire',
        'status': 'pending',
        'dueAt': 'Tomorrow at 5:00 PM',
        'description': 'Mandatory medical disclosure',
      }),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          formsProvider.overrideWith((ref) async => mockForms),
          formDetailProvider('form-123').overrideWith(
            (ref) async => mockForms.first,
          ),
        ],
        child: const MaterialApp(
          home: ResourcesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tab 1: Health Library
    expect(find.text('Health Library'), findsOneWidget);
    expect(find.text('CBT Thought Record Worksheet'), findsOneWidget);
    expect(find.text('5-4-3-2-1 Sensory Grounding Technique'), findsOneWidget);

    // Switch to Tab 2: Forms & Consents
    await tester.tap(find.text('Forms & Consents'));
    await tester.pumpAndSettle();

    expect(find.text('Required Intake & Consents'), findsOneWidget);
    expect(find.text('Telehealth Intake Questionnaire'), findsOneWidget);
    expect(find.text('Open Form'), findsOneWidget);

    // Switch to Tab 3: Crisis Hotlines
    await tester.tap(find.text('Crisis Hotlines'));
    await tester.pumpAndSettle();

    expect(find.text('988 Suicide & Crisis Lifeline'), findsOneWidget);
    expect(find.text('Crisis Text Line'), findsOneWidget);
  });

  testWidgets('TelehealthRoomScreen renders video lobby, controls, arrival check-in, and checklist',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockSession = TelehealthSessionModel.fromJson(const {
      'provider': 'Altrix WebRTC',
      'joinUrl': 'https://telehealth.altrixs.com/room/room-777',
      'status': 'waiting',
    });

    final mockAppointment = AppointmentModel.fromJson(const {
      'id': 'app-1',
      'title': 'Psychiatric Follow-up',
      'clinician': {'name': 'Dr. Marcus Vance'},
      'date': '2026-09-15',
      'startTime': '14:00',
      'endTime': '14:50',
      'isVirtual': true,
      'joinToken': 'mock-token-123',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          telehealthSessionProvider('mock-token-123').overrideWith(
            (ref) async => mockSession,
          ),
        ],
        child: MaterialApp(
          home: TelehealthRoomScreen(
            joinToken: 'mock-token-123',
            appointment: mockAppointment,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Telehealth Lobby'), findsOneWidget);
    expect(find.text('Psychiatric Follow-up'), findsOneWidget);
    expect(find.text('Dr. Marcus Vance'), findsOneWidget);
    expect(find.text('Camera Active · Ready for Doctor'), findsOneWidget);
    expect(find.text("I'm Here / Alert Clinician"), findsOneWidget);
    expect(find.text('Enter Video Consultation'), findsOneWidget);
    expect(find.text('Telehealth Checklist'), findsOneWidget);

    // Toggle camera off
    await tester.tap(find.byTooltip('Toggle Camera'));
    await tester.pumpAndSettle();
    expect(find.text('Camera is off'), findsOneWidget);
  });

  testWidgets('AppointmentEditorScreen displays visit format options for virtual booking',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorsProvider.overrideWith((ref) async => const <DoctorModel>[]),
        ],
        child: const MaterialApp(
          home: AppointmentEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visit format'), findsOneWidget);
    expect(find.text('In-Person Clinic'), findsOneWidget);
    expect(find.text('Virtual Video Visit'), findsOneWidget);

    // Tap Virtual Video Visit
    await tester.tap(find.text('Virtual Video Visit'));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isTrue);
  });
}
