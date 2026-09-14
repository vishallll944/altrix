import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:altrix/features/auth/domain/entities/user.dart';
import 'package:altrix/features/auth/presentation/providers/auth_providers.dart';
import 'package:altrix/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:altrix/features/patient/data/models/patient_models.dart';
import 'package:altrix/features/patient/presentation/providers/patient_providers.dart';
import 'package:altrix/features/profile/data/medical_summary_pdf_service.dart';
import 'package:altrix/features/profile/presentation/screens/privacy_security_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationsScreen', () {
    testWidgets('renders tabs, filter chips, and preference toggles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();

      final dashboard = DashboardModel.fromJson({
        'success': true,
        'data': {
          'notifications': [
            {
              'title': 'Care Team Note',
              'message': 'Your clinician reviewed your wellness check-in.',
              'time': '10:00 AM',
              'isUnread': true,
            },
            {
              'title': 'Appointment Confirmed',
              'message': 'Telehealth visit scheduled for tomorrow.',
              'time': 'Yesterday',
              'isUnread': false,
            }
          ],
          'reminders': [],
          'unreadNotifications': 1,
        },
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            dashboardProvider.overrideWith((ref) => dashboard),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and tabs
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Alerts & Activity'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);

      // Check alerts content
      expect(find.text('Care Team Note'), findsOneWidget);
      expect(find.text('Appointment Confirmed'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);

      // Tap on Preferences tab
      await tester.tap(find.text('Preferences'));
      await tester.pumpAndSettle();

      // Check preferences content
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Clinical & Care Alerts'), findsOneWidget);
      expect(find.text('Appointment Reminders'), findsOneWidget);
      expect(find.text('Care Team Messages'), findsOneWidget);
      expect(find.text('Daily Wellness Check-in'), findsOneWidget);
      expect(find.text('Delivery Channels'), findsOneWidget);
      expect(find.text('Quiet Hours'), findsOneWidget);
    });
  });

  group('PrivacySecurityScreen', () {
    testWidgets('renders HIPAA status, auto-lock, and legal links without biometric unlock', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PrivacySecurityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('HIPAA-Ready & Encrypted'), findsOneWidget);
      expect(find.text('256-Bit AES Data Protection'), findsOneWidget);
      // Biometric unlock is deleted as requested
      expect(find.text('Biometric Unlock'), findsNothing);
      expect(find.text('Auto-Lock Timeout'), findsOneWidget);
      expect(find.text('Two-Factor Authentication (2FA)'), findsOneWidget);
      expect(find.text('Care Team Access'), findsOneWidget);
      expect(find.text('Emergency Medical Access'), findsOneWidget);
      expect(find.text('Export Medical Summary'), findsOneWidget);
      expect(find.text('Notice of Privacy Practices'), findsOneWidget);
      expect(find.text('Delete Account & Data'), findsOneWidget);
    });

    test('MedicalSummaryPdfService generates valid PDF bytes', () async {
      const testUser = User(
        id: 'patient-test-123',
        name: 'John Doe',
        email: 'johndoe@example.com',
        phone: '+1 555-0199',
        emergencyContactName: 'Jane Doe',
        emergencyContactPhone: '+1 555-0198',
      );

      final pdfBytes = await MedicalSummaryPdfService.generatePdf(
        user: testUser,
        appointments: [
          AppointmentModel.fromJson(const {
            'id': 'appt-1',
            'title': 'Consultation',
            'providerName': 'Dr. Sarah Connor',
            'date': '2026-09-20',
            'startTime': '10:00',
            'endTime': '10:50',
            'isVirtual': true,
            'status': 'confirmed',
          }),
        ],
        checkIns: [
          CheckInModel.fromJson(const {
            'id': 'chk-1',
            'mood': 4,
            'stress': 2,
            'sleep': 8,
            'notes': 'Feeling energetic and well-rested',
            'createdAt': '2026-09-14',
          }),
        ],
      );

      expect(pdfBytes, isNotEmpty);
      // PDF documents always start with "%PDF-"
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });
}
