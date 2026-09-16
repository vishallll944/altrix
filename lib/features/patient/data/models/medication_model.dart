import '../../../../core/network/api_response.dart';

/// Status of a single dose for today.
enum MedicationDoseStatus { pending, taken, skipped }

MedicationDoseStatus _parseDoseStatus(String raw) {
  switch (raw.toLowerCase().trim()) {
    case 'taken':
      return MedicationDoseStatus.taken;
    case 'skipped':
      return MedicationDoseStatus.skipped;
    default:
      return MedicationDoseStatus.pending;
  }
}

String _normalizeTime(String raw) {
  final trimmed = raw.trim();
  final parts = trimmed.split(':');
  if (parts.length >= 2) {
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h != null && m != null) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
  }
  return trimmed;
}

/// A single dose intake log entry returned by the backend for today.
class MedicationDoseLog {
  const MedicationDoseLog({
    required this.doseTime,
    required this.status,
    this.loggedAt,
  });

  /// Normalized 24-hour time string, e.g. "08:00".
  final String doseTime;
  final MedicationDoseStatus status;
  final String? loggedAt;

  factory MedicationDoseLog.fromJson(Map<String, dynamic> json) {
    final rawTime = readString(json, ['time', 'doseTime', 'dose_time', 'dose']);
    final isTaken = json['taken'] == true || json['isTaken'] == true;
    final isSkipped = json['skipped'] == true || json['isSkipped'] == true;

    MedicationDoseStatus status;
    if (isTaken) {
      status = MedicationDoseStatus.taken;
    } else if (isSkipped) {
      status = MedicationDoseStatus.skipped;
    } else {
      status = _parseDoseStatus(
        readString(json, ['status', 'state'], fallback: 'pending'),
      );
    }

    return MedicationDoseLog(
      doseTime: _normalizeTime(rawTime),
      status: status,
      loggedAt: readString(json, ['takenAt', 'taken_at', 'loggedAt', 'logged_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'doseTime': doseTime,
        'status': status.name,
        'taken': status == MedicationDoseStatus.taken,
        'skipped': status == MedicationDoseStatus.skipped,
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

  /// Ordered list of normalized 24-hour time strings, e.g. ["08:00", "13:00", "20:00"].
  final List<String> doseTimes;
  final String startDate;
  final String endDate;
  final bool isActive;

  /// Today's intake log keyed by doseTime.
  final List<MedicationDoseLog> todayLogs;

  /// Returns the status for a specific doseTime string.
  MedicationDoseStatus statusFor(String doseTime) {
    final norm = _normalizeTime(doseTime);
    for (final log in todayLogs) {
      if (_normalizeTime(log.doseTime) == norm) return log.status;
    }
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

    // Parse todayLogs / todayDoses — backend sends "todayDoses": [{"time":"08:00","taken":true,...}]
    final rawLogs = payload['todayDoses'] ??
        payload['today_doses'] ??
        payload['doses'] ??
        payload['todayLogs'] ??
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

    // Parse doseTimes — backend may send as array of strings, or derive from todayDoses.
    final rawTimes = payload['doseTimes'] ?? payload['dose_times'] ?? payload['times'];
    final doseTimes = <String>[];
    if (rawTimes is List) {
      for (final t in rawTimes) {
        final s = t?.toString().trim() ?? '';
        if (s.isNotEmpty) doseTimes.add(_normalizeTime(s));
      }
    }
    // Fallback if doseTimes is empty: collect from todayLogs
    if (doseTimes.isEmpty && todayLogs.isNotEmpty) {
      for (final log in todayLogs) {
        if (log.doseTime.isNotEmpty && !doseTimes.contains(log.doseTime)) {
          doseTimes.add(log.doseTime);
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
    final norm = _normalizeTime(doseTime);
    final updatedLogs = List<MedicationDoseLog>.from(todayLogs);
    final idx = updatedLogs.indexWhere((l) => _normalizeTime(l.doseTime) == norm);
    final updated = MedicationDoseLog(
      doseTime: norm,
      status: status,
      loggedAt: DateTime.now().toIso8601String(),
    );
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
