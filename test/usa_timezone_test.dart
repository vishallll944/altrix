import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:altrix/core/utils/usa_timezone_service.dart';
import 'package:altrix/features/auth/presentation/providers/auth_providers.dart';
import 'package:altrix/features/patient/data/models/patient_models.dart';
import 'package:altrix/features/profile/presentation/screens/privacy_security_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UsaTimezoneService', () {
    test('isUsDaylightSaving accurately detects US summer/winter DST dates', () {
      // July 15 is always in US Daylight Saving Time
      final summerDate = DateTime.utc(2026, 7, 15, 12, 0);
      expect(UsaTimezoneService.isUsDaylightSaving(summerDate), isTrue);

      // January 15 is always in US Standard Time
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0);
      expect(UsaTimezoneService.isUsDaylightSaving(winterDate), isFalse);
    });

    test('getUsOffsetHours returns correct offsets for all US zones', () {
      final summerDate = DateTime.utc(2026, 7, 15, 12, 0);
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0);

      // Eastern: UTC-4 (EDT in summer), UTC-5 (EST in winter)
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.eastern, summerDate), -4);
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.eastern, winterDate), -5);

      // Central: UTC-5 (CDT in summer), UTC-6 (CST in winter)
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.central, summerDate), -5);
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.central, winterDate), -6);

      // Mountain: UTC-6 (MDT in summer), UTC-7 (MST in winter)
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.mountain, summerDate), -6);
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.mountain, winterDate), -7);

      // Pacific: UTC-7 (PDT in summer), UTC-8 (PST in winter)
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.pacific, summerDate), -7);
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.pacific, winterDate), -8);

      // Alaska: UTC-8 (AKDT in summer), UTC-9 (AKST in winter)
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.alaska, summerDate), -8);
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.alaska, winterDate), -9);

      // Hawaii: UTC-10 year-round
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.hawaii, summerDate), -10);
      expect(UsaTimezoneService.getUsOffsetHours(UsaTimezone.hawaii, winterDate), -10);
    });

    test('getTimezoneAbbreviation formats correct 3-letter US codes', () {
      final summerDate = DateTime.utc(2026, 7, 15, 12, 0);
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0);

      expect(
        UsaTimezoneService.getTimezoneAbbreviation(summerDate, timezone: UsaTimezone.eastern),
        'EDT',
      );
      expect(
        UsaTimezoneService.getTimezoneAbbreviation(winterDate, timezone: UsaTimezone.eastern),
        'EST',
      );
      expect(
        UsaTimezoneService.getTimezoneAbbreviation(summerDate, timezone: UsaTimezone.pacific),
        'PDT',
      );
      expect(
        UsaTimezoneService.getTimezoneAbbreviation(winterDate, timezone: UsaTimezone.pacific),
        'PST',
      );
    });

    test('formatTime formats in 12-hour AM/PM with US timezone suffix', () {
      // 18:30 UTC in summer -> 14:30 EDT (2:30 PM EDT)
      final utcTime = DateTime.utc(2026, 7, 15, 18, 30);
      final formatted = UsaTimezoneService.formatTime(
        utcTime,
        timezone: UsaTimezone.eastern,
        includeTz: true,
      );
      expect(formatted, '2:30 PM EDT');

      // Pacific in summer -> 11:30 AM PDT
      final formattedPt = UsaTimezoneService.formatTime(
        utcTime,
        timezone: UsaTimezone.pacific,
        includeTz: true,
      );
      expect(formattedPt, '11:30 AM PDT');
    });

    test('formatDate formats in US month-first convention (MM/dd/yyyy and MMM d, yyyy)', () {
      final utcDate = DateTime.utc(2026, 9, 14, 18, 0);
      expect(
        UsaTimezoneService.formatDate(utcDate, timezone: UsaTimezone.eastern, numeric: true),
        '09/14/2026',
      );
      expect(
        UsaTimezoneService.formatDate(utcDate, timezone: UsaTimezone.eastern, numeric: false),
        'Sep 14, 2026',
      );
    });

    test('AppointmentModel parses UTC startsAt and converts to US timezone', () {
      final appt = AppointmentModel.fromJson(const {
        'id': 'appt-utc-1',
        'title': 'Telehealth Visit',
        'startsAt': '2026-07-15T18:30:00.000Z',
        'isVirtual': true,
      });

      // 18:30 UTC -> 14:30 EDT (2:30 PM)
      expect(appt.timeLabel, '2:30 PM');
      expect(appt.dateLabel, contains('Jul 15'));
    });

    test('formatTimeString and DashboardItem.formattedTime converts times to 12-hour format with AM/PM', () {
      expect(UsaTimezoneService.formatTimeString('14:30'), '2:30 PM');
      expect(UsaTimezoneService.formatTimeString('09:15'), '9:15 AM');
      expect(UsaTimezoneService.formatTimeString('00:45'), '12:45 AM');
      expect(UsaTimezoneService.formatTimeString('12:00'), '12:00 PM');
      expect(UsaTimezoneService.formatTimeString('2:30 pm'), '2:30 PM');
      expect(UsaTimezoneService.formatTimeString('08:30 AM'), '8:30 AM');

      const item24 = DashboardItem(
        title: 'Medication',
        body: 'Take evening dose',
        time: '19:45',
        isUnread: false,
      );
      expect(item24.formattedTime, '7:45 PM');

      const itemMorning = DashboardItem(
        title: 'Check-in',
        body: 'Morning assessment',
        time: '08:00',
        isUnread: true,
      );
      expect(itemMorning.formattedTime, '8:00 AM');
    });
  });

  group('USA Timezone in PrivacySecurityScreen', () {
    testWidgets('renders Timezone (USA) tile and allows changing US timezone', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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

      // Find Timezone (USA) tile
      final tzTile = find.text('Timezone (USA)');
      await tester.ensureVisible(tzTile);
      await tester.pumpAndSettle();

      expect(tzTile, findsOneWidget);
      expect(find.text('Timezone & Localization'), findsOneWidget);

      // Tap on Timezone tile to open bottom sheet
      await tester.tap(tzTile);
      await tester.pumpAndSettle();

      // Bottom sheet with US timezones
      expect(find.text('Select USA Timezone'), findsOneWidget);
      expect(find.textContaining('Eastern Time'), findsOneWidget);
      expect(find.textContaining('Central Time'), findsOneWidget);
      expect(find.textContaining('Pacific Time'), findsOneWidget);

      // Select Pacific Time
      await tester.tap(find.textContaining('Pacific Time'));
      await tester.pumpAndSettle();

      // Verify preference saved
      expect(prefs.getString(kPrefUsaTimezone), 'pacific');
      expect(find.text('PT'), findsOneWidget);
    });
  });
}
