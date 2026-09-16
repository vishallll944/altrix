import '../../../../core/network/api_response.dart';

/// Status of a single dose for today.
enum MedicationDoseStatus { pending, taken, skipped }

MedicationDoseStatus _parseDoseStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'taken':
      return MedicationDoseStatus.taken;
    case 'skipped':
      return MedicationDoseStatus.skipped;
    default:
      return MedicationDoseStatus.pending;
  }
}

/// A single dose intake log entry returned by the backend for today.
class MedicationDoseLog {
  const MedicationDoseLog({
    required this.doseTime,
    required this.status,
    this.loggedAt,
  });

  /// 24-hour time string, e.g. "08:00".
  final String doseTime;
  final MedicationDoseStatus status;
  final String? loggedAt;

  factory MedicationDoseLog.fromJson(Map<String, dynamic> json) {
    return MedicationDoseLog(
      doseTime: readString(json, ['doseTime', 'dose_time', 'time']),
      status: _parseDoseStatus(
        readString(json, ['status', 'state'], fallback: 'pending'),
      ),
      loggedAt: readString(json, ['loggedAt', 'logged_at', 'takenAt', 'taken_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'doseTime': doseTime,
        'status': status.name,
        if (loggedAt != null) 'loggedAt': loggedAt,
      };

  MedicationDoseLog copyWith({MedicationDoseStatus? status}) {
    return MedicationDoseLog(
      doseTime: doseTime,
      status: status ?? this.status,
      loggedAt: loggedAt,
    );
  }
}

/// A single active medication prescription / schedule.
class MedicationScheduleModel {
  const MedicationScheduleModel({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.instructions,
    required this.doseTimes,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.todayLogs,
  });

  final String id;
  final String medicationName;
  final String dosage;
  final String instructions;

  /// Ordered list of 24-hour time strings, e.g. ["08:00", "13:00", "21:00"].
  final List<String> doseTimes;
  final String startDate;
  final String endDate;
  final bool isActive;

  /// Today's intake log keyed by doseTime.
  final List<MedicationDoseLog> todayLogs;

  /// Returns the status for a specific doseTime string.
  MedicationDoseStatus statusFor(String doseTime) {
    for (final log in todayLogs) {
      if (log.doseTime == doseTime) return log.status;
    }
    // If past the scheduled time with no log, still show as pending.
    return MedicationDoseStatus.pending;
  }

  /// Count of today's pending doses (not yet taken or skipped).
  int get pendingCount =>
      doseTimes.where((t) => statusFor(t) == MedicationDoseStatus.pending).length;

  /// Count of today's taken doses.
  int get takenCount =>
      doseTimes.where((t) => statusFor(t) == MedicationDoseStatus.taken).length;

  factory MedicationScheduleModel.fromJson(Map<String, dynamic> json) {
    final payload = json.containsKey('id') || json.containsKey('_id')
        ? json
        : (json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json);

    // Parse doseTimes — backend may send as array of strings.
    final rawTimes = payload['doseTimes'] ?? payload['dose_times'] ?? payload['times'];
    final doseTimes = <String>[];
    if (rawTimes is List) {
      for (final t in rawTimes) {
        final s = t?.toString().trim() ?? '';
        if (s.isNotEmpty) doseTimes.add(s);
      }
    }

    // Parse todayLogs — backend may send as array of log objects or a map.
    final rawLogs = payload['todayLogs'] ??
        payload['today_logs'] ??
        payload['intakeLogs'] ??
        payload['intake_logs'] ??
        <dynamic>[];
    final todayLogs = <MedicationDoseLog>[];
    if (rawLogs is List) {
      for (final l in rawLogs) {
        if (l is Map<String, dynamic>) {
          todayLogs.add(MedicationDoseLog.fromJson(l));
        } else if (l is Map) {
          todayLogs.add(MedicationDoseLog.fromJson(Map<String, dynamic>.from(l)));
        }
      }
    }

    return MedicationScheduleModel(
      id: readString(payload, ['id', '_id', 'scheduleId', 'schedule_id']),
      medicationName: readString(payload, [
        'medicationName',
        'medication_name',
        'name',
        'medicine',
        'drug',
        'drugName',
      ]),
      dosage: readString(payload, ['dosage', 'dose', 'strength', 'amount']),
      instructions: readString(payload, [
        'instructions',
        'instruction',
        'notes',
        'directions',
        'usage',
      ]),
      doseTimes: doseTimes,
      startDate: readString(payload, ['startDate', 'start_date', 'from']),
      endDate: readString(payload, ['endDate', 'end_date', 'to', 'until']),
      isActive: readBool(payload, ['isActive', 'is_active', 'active'], fallback: true),
      todayLogs: todayLogs,
    );
  }

  MedicationScheduleModel withUpdatedLog(String doseTime, MedicationDoseStatus status) {
    final updatedLogs = List<MedicationDoseLog>.from(todayLogs);
    final idx = updatedLogs.indexWhere((l) => l.doseTime == doseTime);
    final updated = MedicationDoseLog(doseTime: doseTime, status: status);
    if (idx >= 0) {
      updatedLogs[idx] = updated;
    } else {
      updatedLogs.add(updated);
    }
    return MedicationScheduleModel(
      id: id,
      medicationName: medicationName,
      dosage: dosage,
      instructions: instructions,
      doseTimes: doseTimes,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      todayLogs: updatedLogs,
    );
  }
}
