import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

/// Supported US Timezones
enum UsaTimezone {
  auto('Auto (Device / US Local)', 'Auto'),
  eastern('Eastern Time (New York, Atlanta, Miami)', 'ET'),
  central('Central Time (Chicago, Dallas, Houston)', 'CT'),
  mountain('Mountain Time (Denver, Phoenix, Salt Lake)', 'MT'),
  pacific('Pacific Time (Los Angeles, Seattle, SF)', 'PT'),
  alaska('Alaska Time (Anchorage, Juneau)', 'AKT'),
  hawaii('Hawaii Time (Honolulu)', 'HT');

  const UsaTimezone(this.displayName, this.shortCode);

  final String displayName;
  final String shortCode;

  static UsaTimezone fromCode(String? code) {
    if (code == null || code.isEmpty) return UsaTimezone.auto;
    for (final tz in UsaTimezone.values) {
      if (tz.name.toLowerCase() == code.toLowerCase() ||
          tz.shortCode.toLowerCase() == code.toLowerCase()) {
        return tz;
      }
    }
    return UsaTimezone.auto;
  }
}

/// Key for storing the user's preferred US timezone in SharedPreferences
const String kPrefUsaTimezone = 'pref_usa_timezone';

/// Riverpod provider for active USA timezone
final usaTimezoneProvider =
    NotifierProvider<UsaTimezoneNotifier, UsaTimezone>(UsaTimezoneNotifier.new);

class UsaTimezoneNotifier extends Notifier<UsaTimezone> {
  @override
  UsaTimezone build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final saved = prefs.getString(kPrefUsaTimezone);
      return UsaTimezone.fromCode(saved);
    } catch (_) {
      return UsaTimezone.auto;
    }
  }

  Future<void> setTimezone(UsaTimezone timezone) async {
    state = timezone;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(kPrefUsaTimezone, timezone.name);
    } catch (_) {}
  }
}

/// Comprehensive USA Timezone and Date/Time utility service.
class UsaTimezoneService {
  UsaTimezoneService._();

  static const _usTzNames = {
    'est', 'edt', 'cst', 'cdt', 'mst', 'mdt', 'pst', 'pdt', 'akst', 'akdt', 'hst', 'hdt',
  };

  /// Returns whether the current device is in a US timezone based on timezone name or offset.
  static bool isDeviceInUsa([DateTime? testDate]) {
    final date = testDate ?? DateTime.now();
    final name = date.timeZoneName.toLowerCase();
    if (_usTzNames.contains(name)) return true;

    // US continental offsets range between -4 (EDT) and -10 (HST)
    final offsetHours = date.timeZoneOffset.inHours;
    return offsetHours >= -10 && offsetHours <= -4;
  }

  /// Determines whether a given UTC or local date falls within US Daylight Saving Time.
  /// (US DST begins 2nd Sunday of March at 2:00 AM and ends 1st Sunday of November at 2:00 AM).
  static bool isUsDaylightSaving(DateTime date) {
    final year = date.year;

    // Find 2nd Sunday in March
    var marchFirst = DateTime.utc(year, 3, 1);
    var marchSundays = 0;
    var dstStartDay = 8;
    for (int d = 1; d <= 14; d++) {
      if (DateTime.utc(year, 3, d).weekday == DateTime.sunday) {
        marchSundays++;
        if (marchSundays == 2) {
          dstStartDay = d;
          break;
        }
      }
    }
    final dstStart = DateTime.utc(year, 3, dstStartDay, 2);

    // Find 1st Sunday in November
    var dstEndDay = 1;
    for (int d = 1; d <= 7; d++) {
      if (DateTime.utc(year, 11, d).weekday == DateTime.sunday) {
        dstEndDay = d;
        break;
      }
    }
    final dstEnd = DateTime.utc(year, 11, dstEndDay, 2);

    final utcDate = date.isUtc ? date : date.toUtc();
    return utcDate.isAfter(dstStart) && utcDate.isBefore(dstEnd);
  }

  /// Gets the UTC offset in hours for a specific US timezone.
  static int getUsOffsetHours(UsaTimezone tz, DateTime forDate) {
    final isDst = isUsDaylightSaving(forDate);

    switch (tz) {
      case UsaTimezone.eastern:
        return isDst ? -4 : -5;
      case UsaTimezone.central:
        return isDst ? -5 : -6;
      case UsaTimezone.mountain:
        return isDst ? -6 : -7;
      case UsaTimezone.pacific:
        return isDst ? -7 : -8;
      case UsaTimezone.alaska:
        return isDst ? -8 : -9;
      case UsaTimezone.hawaii:
        return -10; // Hawaii does not observe DST
      case UsaTimezone.auto:
        if (isDeviceInUsa(forDate)) {
          return forDate.timeZoneOffset.inHours;
        }
        // If device is outside USA, default to US Eastern Time (standard healthcare time)
        return isDst ? -4 : -5;
    }
  }

  /// Returns the standard 3-letter US timezone abbreviation for a given date and timezone.
  static String getTimezoneAbbreviation(DateTime date, {UsaTimezone timezone = UsaTimezone.auto}) {
    if (timezone == UsaTimezone.auto && isDeviceInUsa(date)) {
      final name = date.timeZoneName.toUpperCase();
      if (_usTzNames.contains(name.toLowerCase())) return name;
    }

    final isDst = isUsDaylightSaving(date);
    switch (timezone) {
      case UsaTimezone.eastern:
        return isDst ? 'EDT' : 'EST';
      case UsaTimezone.central:
        return isDst ? 'CDT' : 'CST';
      case UsaTimezone.mountain:
        return isDst ? 'MDT' : 'MST';
      case UsaTimezone.pacific:
        return isDst ? 'PDT' : 'PST';
      case UsaTimezone.alaska:
        return isDst ? 'AKDT' : 'AKST';
      case UsaTimezone.hawaii:
        return 'HST';
      case UsaTimezone.auto:
        return isDst ? 'EDT' : 'EST';
    }
  }

  /// Converts any [DateTime] (UTC or local) to the target US timezone.
  static DateTime toUsTime(DateTime dt, {UsaTimezone timezone = UsaTimezone.auto}) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    final offsetHours = getUsOffsetHours(timezone, utc);
    return utc.add(Duration(hours: offsetHours));
  }

  /// Returns the current time in the designated US timezone.
  static DateTime nowInUs({UsaTimezone timezone = UsaTimezone.auto}) {
    return toUsTime(DateTime.now().toUtc(), timezone: timezone);
  }

  /// Formats a time in standard USA 12-hour format: `h:mm a` (e.g. `2:30 PM` or `2:30 PM EDT`).
  static String formatTime(
    DateTime dt, {
    UsaTimezone timezone = UsaTimezone.auto,
    bool includeTz = true,
  }) {
    final usTime = toUsTime(dt, timezone: timezone);
    final formattedTime = DateFormat('h:mm a').format(usTime);
    if (!includeTz) return formattedTime;
    final tzAbbr = getTimezoneAbbreviation(dt, timezone: timezone);
    return '$formattedTime $tzAbbr';
  }

  /// Formats a date in standard USA format: `MM/dd/yyyy` or `MMM d, yyyy` (e.g. `Sep 14, 2026`).
  static String formatDate(
    DateTime dt, {
    UsaTimezone timezone = UsaTimezone.auto,
    bool numeric = false,
  }) {
    final usTime = toUsTime(dt, timezone: timezone);
    if (numeric) {
      return DateFormat('MM/dd/yyyy').format(usTime);
    }
    return DateFormat('MMM d, yyyy').format(usTime);
  }

  /// Formats relative date like "Today", "Tomorrow", "Yesterday", or "Mon, Sep 14".
  static String formatRelativeDate(
    DateTime dt, {
    UsaTimezone timezone = UsaTimezone.auto,
    DateTime? referenceNow,
  }) {
    final target = toUsTime(dt, timezone: timezone);
    final now = referenceNow != null
        ? toUsTime(referenceNow, timezone: timezone)
        : nowInUs(timezone: timezone);

    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);

    final difference = targetDay.difference(today).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return DateFormat('EEE, MMM d').format(target);
  }

  /// Formats full appointment datetime line in USA format: e.g. `Today · 2:00 PM EDT` or `Mon, Sep 15 · 10:00 AM EDT`.
  static String formatAppointmentWhen(
    DateTime dt, {
    UsaTimezone timezone = UsaTimezone.auto,
    DateTime? referenceNow,
    bool includeTz = true,
  }) {
    final dayLabel = formatRelativeDate(dt, timezone: timezone, referenceNow: referenceNow);
    final timeStr = formatTime(dt, timezone: timezone, includeTz: includeTz);
    return '$dayLabel  ·  $timeStr';
  }

  /// Formats any time string (ISO 8601, 24-hour HH:mm, or existing AM/PM)
  /// into USA standard 12-hour format: `h:mm a` (e.g. `2:30 PM`).
  static String formatTimeString(
    String rawTime, {
    UsaTimezone timezone = UsaTimezone.auto,
    bool includeTz = false,
  }) {
    final trimmed = rawTime.trim();
    if (trimmed.isEmpty) return '';

    // If it's a full ISO-8601 DateTime string (e.g. 2026-09-14T14:30:00Z or 2026-09-14 14:30:00)
    final parsedDt = DateTime.tryParse(trimmed) ??
        DateTime.tryParse(trimmed.replaceAll(' ', 'T'));
    if (parsedDt != null) {
      return formatTime(parsedDt, timezone: timezone, includeTz: includeTz);
    }

    // Already 12-hour AM/PM: e.g. "2:30 PM", "02:30 pm", "10:00 AM"
    final amPmMatch = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])$')
        .firstMatch(trimmed);
    if (amPmMatch != null) {
      final hour = int.tryParse(amPmMatch.group(1)!);
      final minute = amPmMatch.group(2)!;
      final period = amPmMatch.group(3)!.toUpperCase();
      if (hour != null) {
        final hour12 = hour % 12 == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$hour12:$minute $period';
      }
    }

    // 24-hour clock: e.g. "14:30", "14:30:00", "09:15"
    final clock24Match =
        RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(trimmed);
    if (clock24Match != null) {
      final hour = int.tryParse(clock24Match.group(1)!);
      final minute = clock24Match.group(2)!;
      if (hour != null && hour >= 0 && hour < 24) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour % 12 == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$hour12:$minute $period';
      }
    }

    return trimmed;
  }
}
