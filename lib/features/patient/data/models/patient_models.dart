import '../../../../core/network/api_response.dart';

class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.title,
    required this.providerName,
    required this.dateLabel,
    required this.timeLabel,
    required this.endTimeLabel,
    required this.visitType,
    required this.duration,
    required this.isVirtual,
    required this.status,
    required this.joinToken,
    required this.joinUrl,
    required this.location,
    required this.note,
    required this.sortDateTime,
    required this.raw,
  });

  final String id;
  final String title;
  final String providerName;
  final String dateLabel;
  final String timeLabel;
  final String endTimeLabel;
  final String visitType;
  final String duration;
  final bool isVirtual;
  final String status;
  final String joinToken;
  final String joinUrl;
  final String location;
  final String note;
  final DateTime? sortDateTime;
  final Map<String, dynamic> raw;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final nestedProvider = _readNestedName(json, [
      'clinician',
      'doctor',
      'provider',
      'therapist',
    ]);

    final type = readString(json, ['type', 'visitType', 'visit_type', 'title']);
    final virtualFlag = readBool(json, ['isVirtual', 'is_virtual', 'virtual']);
    final typeLower = type.toLowerCase();
    final isVirtual = virtualFlag ||
        typeLower.contains('virtual') ||
        typeLower.contains('telehealth') ||
        typeLower.contains('video');

    final date = readString(json, ['date', 'dateLabel', 'date_label', 'day']);
    final startTime = readString(json, [
      'startTime',
      'start_time',
      'time',
      'timeLabel',
      'time_label',
    ]);
    final endTime = readString(json, ['endTime', 'end_time']);
    final startsAt = readString(json, ['startsAt', 'starts_at', 'scheduledAt', 'scheduled_at']);
    final sortDateTime = _parseSortDateTime(
      startsAt: startsAt,
      date: date,
      startTime: startTime,
    );

  final formattedDate = _formatDateLabel(sortDateTime, date);
  final formattedStart = _formatTimeLabel(startTime, sortDateTime);
  final formattedEnd = _formatTimeLabel(endTime, null);

    return AppointmentModel(
      id: readString(json, ['id', '_id']),
      title: type.isNotEmpty ? type : 'Appointment',
      providerName: readString(json, [
        'providerName',
        'provider_name',
        'clinicianName',
        'clinician_name',
        'doctorName',
        'doctor_name',
        'provider',
      ], fallback: nestedProvider),
      dateLabel: formattedDate,
      timeLabel: formattedStart,
      endTimeLabel: formattedEnd,
      visitType: isVirtual ? 'Video visit' : 'In-person visit',
      duration: _formatDuration(
        startTime: startTime,
        endTime: endTime,
        fallback: readString(json, ['duration', 'durationLabel'], fallback: '50 min'),
      ),
      isVirtual: isVirtual,
      status: readString(json, ['status', 'state'], fallback: 'scheduled'),
      joinToken: readString(json, ['joinToken', 'join_token', 'telehealthToken']),
      joinUrl: readString(json, ['joinUrl', 'join_url', 'meetingUrl', 'meeting_url']),
      location: readString(json, ['location', 'address', 'clinicName', 'clinic_name']),
      note: readString(json, ['note', 'notes', 'reason']),
      sortDateTime: sortDateTime,
      raw: json,
    );
  }

  String get displayWhen {
    if (dateLabel.isNotEmpty && timeLabel.isNotEmpty) {
      return '$dateLabel  ·  $timeLabel';
    }
    if (dateLabel.isNotEmpty) return dateLabel;
    if (timeLabel.isNotEmpty) return timeLabel;
    return readString(raw, ['startsAt', 'starts_at', 'scheduledAt', 'scheduled_at']);
  }

  String get subtitleLine {
    final parts = <String>[
      if (providerName.isNotEmpty) providerName,
      visitType,
      if (duration.isNotEmpty) duration,
    ];
    return parts.join('  ·  ');
  }

  String get effectiveJoinUrl {
    if (joinUrl.isNotEmpty) return joinUrl;
    return readString(raw, [
      'joinUrl',
      'join_url',
      'meetingUrl',
      'meeting_url',
      'zoomUrl',
      'zoom_url',
      'url',
    ]);
  }

  bool get hasJoinLink => effectiveJoinUrl.trim().isNotEmpty;
}

String _readNestedName(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      final name = readString(value, ['name', 'fullName', 'full_name', 'title']);
      if (name.isNotEmpty) return name;
    }
  }
  return '';
}

DateTime? _parseSortDateTime({
  required String startsAt,
  required String date,
  required String startTime,
}) {
  if (startsAt.isNotEmpty) {
    return DateTime.tryParse(startsAt)?.toLocal();
  }
  if (date.isEmpty) return null;

  final normalizedDate = date.contains('T') ? date.split('T').first : date;
  if (startTime.isEmpty) {
    return DateTime.tryParse(normalizedDate);
  }

  final time = startTime.length == 5 ? '$startTime:00' : startTime;
  return DateTime.tryParse('${normalizedDate}T$time')?.toLocal();
}

String _formatDateLabel(DateTime? sortDateTime, String rawDate) {
  if (sortDateTime != null) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(sortDateTime.year, sortDateTime.month, sortDateTime.day);
    if (day == today) return 'Today';
    if (day == today.add(const Duration(days: 1))) return 'Tomorrow';

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[sortDateTime.weekday - 1]}, '
        '${months[sortDateTime.month - 1]} ${sortDateTime.day}';
  }
  return rawDate;
}

String _formatTimeLabel(String rawTime, DateTime? sortDateTime) {
  if (sortDateTime != null) {
    final hour = sortDateTime.hour;
    final minute = sortDateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }
  return rawTime;
}

String _formatDuration({
  required String startTime,
  required String endTime,
  required String fallback,
}) {
  if (startTime.isEmpty || endTime.isEmpty) return fallback;

  final start = _minutesFromClock(startTime);
  final end = _minutesFromClock(endTime);
  if (start == null || end == null || end <= start) return fallback;

  final minutes = end - start;
  if (minutes % 60 == 0) return '${minutes ~/ 60} hr';
  return '$minutes min';
}

int? _minutesFromClock(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

class DoctorModel {
  const DoctorModel({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.raw,
  });

  final String id;
  final String name;
  final String title;
  final String specialty;
  final Map<String, dynamic> raw;

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: readString(json, ['id', '_id', 'clinicianId', 'clinician_id']),
      name: readString(json, ['name', 'fullName', 'full_name']),
      title: readString(json, ['title', 'credentials']),
      specialty: readString(json, ['specialty', 'role', 'type']),
      raw: json,
    );
  }
}

class AvailabilitySlotModel {
  const AvailabilitySlotModel({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.raw,
  });

  final String date;
  final String startTime;
  final String endTime;
  final Map<String, dynamic> raw;

  factory AvailabilitySlotModel.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlotModel(
      date: readString(json, ['date', 'day']),
      startTime: readString(json, ['startTime', 'start_time', 'from']),
      endTime: readString(json, ['endTime', 'end_time', 'to']),
      raw: json,
    );
  }
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.preview,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.topic,
    required this.raw,
  });

  final String id;
  final String title;
  final String preview;
  final String lastMessageAt;
  final int unreadCount;
  final String topic;
  final Map<String, dynamic> raw;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: readString(json, ['id', '_id', 'conversationId']),
      title: readString(json, ['title', 'name', 'clinicName', 'clinic_name']),
      preview: readString(json, [
        'preview',
        'lastMessage',
        'last_message',
        'message',
        'body',
      ]),
      lastMessageAt: readString(json, [
        'lastMessageAt',
        'last_message_at',
        'updatedAt',
        'updated_at',
        'time',
      ]),
      unreadCount: readInt(json, ['unreadCount', 'unread_count', 'unread']) ?? 0,
      topic: readString(json, ['topic', 'category']),
      raw: json,
    );
  }
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.body,
    required this.sender,
    required this.createdAt,
    required this.isRead,
    required this.raw,
  });

  final String id;
  final String body;
  final String sender;
  final String createdAt;
  final bool isRead;
  final Map<String, dynamic> raw;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: readString(json, ['id', '_id', 'messageId']),
      body: readString(json, ['message', 'body', 'text', 'content']),
      sender: readString(json, ['sender', 'from', 'author', 'role']),
      createdAt: readString(json, ['createdAt', 'created_at', 'sentAt', 'sent_at']),
      isRead: readBool(json, ['isRead', 'is_read', 'read'], fallback: true),
      raw: json,
    );
  }
}

class CheckInModel {
  const CheckInModel({
    required this.id,
    required this.mood,
    required this.stress,
    required this.sleep,
    required this.journal,
    required this.createdAt,
    required this.raw,
  });

  final String id;
  final int? mood;
  final int? stress;
  final int? sleep;
  final String journal;
  final String createdAt;
  final Map<String, dynamic> raw;

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      id: readString(json, ['id', '_id']),
      mood: readInt(json, ['mood']),
      stress: readInt(json, ['stress']),
      sleep: readInt(json, ['sleep']),
      journal: readString(json, ['journal', 'note', 'notes']),
      createdAt: readString(json, ['createdAt', 'created_at', 'date']),
      raw: json,
    );
  }
}

class DashboardItem {
  const DashboardItem({
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
  });

  final String title;
  final String body;
  final String time;
  final bool isUnread;

  factory DashboardItem.fromJson(Map<String, dynamic> json) {
    final isRead = readBool(json, ['isRead', 'is_read', 'read'], fallback: true);
    return DashboardItem(
      title: readString(json, ['title', 'subject', 'name', 'label']),
      body: readString(json, ['body', 'message', 'text', 'preview', 'description']),
      time: readString(json, [
        'time',
        'createdAt',
        'created_at',
        'dueAt',
        'due_at',
        'lastMessageAt',
        'last_message_at',
      ]),
      isUnread: readBool(json, ['isUnread', 'is_unread', 'unread']) || !isRead,
    );
  }

  String get displayText {
    if (title.isNotEmpty && body.isNotEmpty) return '$title — $body';
    return title.isNotEmpty ? title : body;
  }
}

class DashboardModel {
  const DashboardModel({
    required this.nextAppointment,
    required this.upcomingAppointments,
    required this.reminders,
    required this.notifications,
    required this.pendingTasks,
    required this.unreadMessages,
    required this.unreadNotifications,
    required this.pendingForms,
    required this.upcomingAppointmentsCount,
    required this.clinicName,
    required this.headline,
    required this.checkInStreak,
    required this.todayCheckInCompleted,
    required this.todayMood,
    required this.todayStress,
    required this.todaySleep,
    required this.latestMood,
    required this.latestStress,
    required this.latestSleep,
    required this.weeklyCheckInsCompleted,
    required this.weeklyAverageMood,
    required this.weeklyAverageStress,
    required this.weeklyAverageSleep,
    required this.recommendedWellnessTool,
    required this.safetyPlanAvailable,
    required this.safetyPlanSigned,
    required this.raw,
  });

  final AppointmentModel? nextAppointment;
  final List<AppointmentModel> upcomingAppointments;
  final List<DashboardItem> reminders;
  final List<DashboardItem> notifications;
  final List<DashboardItem> pendingTasks;
  final int unreadMessages;
  final int unreadNotifications;
  final int pendingForms;
  final int upcomingAppointmentsCount;
  final String clinicName;
  final String headline;
  final int checkInStreak;
  final bool todayCheckInCompleted;
  final double? todayMood;
  final double? todayStress;
  final double? todaySleep;
  final double? latestMood;
  final double? latestStress;
  final double? latestSleep;
  final int weeklyCheckInsCompleted;
  final double? weeklyAverageMood;
  final double? weeklyAverageStress;
  final double? weeklyAverageSleep;
  final String recommendedWellnessTool;
  final bool safetyPlanAvailable;
  final bool safetyPlanSigned;
  final Map<String, dynamic> raw;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final payload = unwrapApiPayload(json);
    final stats = payload['stats'];
    final statsMap = stats is Map<String, dynamic> ? stats : const <String, dynamic>{};
    final profile = payload['profile'];
    final profileMap =
        profile is Map<String, dynamic> ? profile : const <String, dynamic>{};
    final todayCheckIn = payload['todayCheckIn'] ?? payload['today_check_in'];
    final todayMap = todayCheckIn is Map<String, dynamic>
        ? todayCheckIn
        : const <String, dynamic>{};
    final latestScores = payload['latestScores'] ?? payload['latest_scores'];
    final latestMap = latestScores is Map<String, dynamic>
        ? latestScores
        : const <String, dynamic>{};
    final weeklyProgress = payload['weeklyProgress'] ?? payload['weekly_progress'];
    final weeklyMap = weeklyProgress is Map<String, dynamic>
        ? weeklyProgress
        : const <String, dynamic>{};
    final safetyPlan = payload['safetyPlan'] ?? payload['safety_plan'];
    final safetyMap =
        safetyPlan is Map<String, dynamic> ? safetyPlan : const <String, dynamic>{};

    AppointmentModel? next;
    final nextJson = payload['nextAppointment'] ?? payload['next_appointment'];
    if (nextJson is Map<String, dynamic>) {
      next = AppointmentModel.fromJson(nextJson);
    }

    final upcoming = extractListFromPayload(
      payload,
      keys: const ['upcomingAppointments', 'upcoming_appointments', 'appointments'],
    ).map(AppointmentModel.fromJson).toList();

    if (next == null && upcoming.isNotEmpty) {
      next = upcoming.first;
    }

    final pendingTasks = extractListFromPayload(
      payload,
      keys: const ['pendingTasks', 'pending_tasks', 'tasks'],
    ).map(DashboardItem.fromJson).toList();

    final reminders = extractListFromPayload(
      payload,
      keys: const ['reminders', 'careTeam', 'care_team', 'updates'],
    ).map(DashboardItem.fromJson).toList();

    final notifications = extractListFromPayload(
      payload,
      keys: const ['notifications', 'alerts'],
    ).map(DashboardItem.fromJson).toList();

    final effectiveReminders = reminders.isNotEmpty ? reminders : pendingTasks;

    return DashboardModel(
      nextAppointment: next,
      upcomingAppointments: upcoming,
      reminders: effectiveReminders,
      notifications: notifications,
      pendingTasks: pendingTasks,
      unreadMessages: readInt(payload, [
            'unreadMessageCount',
            'unreadMessages',
            'unread_messages',
          ]) ??
          readInt(statsMap, ['unreadMessages', 'unread_messages']) ??
          0,
      unreadNotifications:
          readInt(payload, ['unreadNotifications', 'unread_notifications']) ??
              readInt(statsMap, ['unreadNotifications', 'unread_notifications']) ??
              notifications.where((item) => item.isUnread).length,
      pendingForms: readInt(payload, ['pendingForms', 'formsDue', 'forms_due']) ??
          readInt(statsMap, ['pendingForms', 'formsDue', 'forms_due']) ??
          pendingTasks.length,
      upcomingAppointmentsCount: readInt(
            payload,
            ['upcomingAppointmentsCount', 'upcoming_appointments_count', 'appointmentsCount'],
          ) ??
          readInt(statsMap, ['upcomingAppointmentsCount', 'appointmentsCount']) ??
          upcoming.length,
      clinicName: readString(payload, ['clinicName', 'clinic_name', 'clinic']),
      headline: readString(payload, ['headline', 'welcomeMessage', 'welcome_message', 'greeting']),
      checkInStreak: readInt(profileMap, ['checkInStreak', 'check_in_streak']) ?? 0,
      todayCheckInCompleted: readBool(todayMap, ['completed', 'done']),
      todayMood: readDouble(todayMap, ['mood']),
      todayStress: readDouble(todayMap, ['stress']),
      todaySleep: readDouble(todayMap, ['sleep']),
      latestMood: readDouble(latestMap, ['mood']),
      latestStress: readDouble(latestMap, ['stress']),
      latestSleep: readDouble(latestMap, ['sleep']),
      weeklyCheckInsCompleted:
          readInt(weeklyMap, ['checkInsCompleted', 'check_ins_completed']) ?? 0,
      weeklyAverageMood: readDouble(weeklyMap, ['averageMood', 'average_mood']),
      weeklyAverageStress: readDouble(weeklyMap, ['averageStress', 'average_stress']),
      weeklyAverageSleep: readDouble(weeklyMap, ['averageSleep', 'average_sleep']),
      recommendedWellnessTool: readString(payload, [
        'recommendedWellnessTool',
        'recommended_wellness_tool',
        'wellnessTool',
      ]),
      safetyPlanAvailable: readBool(safetyMap, ['available']),
      safetyPlanSigned: readBool(safetyMap, ['clientSigned', 'client_signed']),
      raw: payload,
    );
  }
}

class ProgressModel {
  const ProgressModel({
    required this.streak,
    required this.longestStreak,
    required this.checkInsCount,
    required this.averageMood,
    required this.averageStress,
    required this.averageSleep,
    required this.riskLevel,
    required this.summary,
    required this.insight,
    required this.moodTrend,
    required this.raw,
  });

  final int? streak;
  final int? longestStreak;
  final int? checkInsCount;
  final double? averageMood;
  final double? averageStress;
  final double? averageSleep;
  final String riskLevel;
  final String summary;
  final String insight;
  final List<int> moodTrend;
  final Map<String, dynamic> raw;

  bool get hasData {
    return (streak != null && streak! > 0) ||
        (longestStreak != null && longestStreak! > 0) ||
        (checkInsCount != null && checkInsCount! > 0) ||
        averageMood != null ||
        averageStress != null ||
        averageSleep != null ||
        riskLevel.isNotEmpty ||
        summary.isNotEmpty ||
        insight.isNotEmpty ||
        moodTrend.isNotEmpty;
  }

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    final payload = unwrapApiPayload(json);
    final nested = payload['progress'];
    final weekly = payload['weekly'];
    final weeklyMap =
        weekly is Map<String, dynamic> ? weekly : const <String, dynamic>{};
    final source = nested is Map<String, dynamic>
        ? nested
        : weeklyMap.isNotEmpty
            ? weeklyMap
            : payload;

    final daily = weeklyMap['daily'];
    final moodTrend = daily is List
        ? daily
            .map((item) {
              if (item is! Map<String, dynamic>) return null;
              final mood = item['mood'];
              if (mood is int) return mood;
              if (mood is num) return mood.round();
              return int.tryParse(mood?.toString() ?? '');
            })
            .whereType<int>()
            .toList()
        : readIntList(source, [
            'moodTrend',
            'mood_trend',
            'weeklyMood',
            'weekly_mood',
            'moodHistory',
            'mood_history',
          ]);

    final riskLevel = () {
      final fromRoot = readString(payload, ['riskLevel', 'risk_level', 'risk', 'status']);
      if (fromRoot.isNotEmpty) return fromRoot;
      return readString(source, ['riskLevel', 'risk_level', 'risk', 'status']);
    }();

    return ProgressModel(
      streak: readInt(payload, ['streak', 'currentStreak', 'current_streak']) ??
          readInt(source, ['streak', 'currentStreak', 'current_streak']),
      longestStreak: readInt(source, ['longestStreak', 'longest_streak', 'bestStreak']),
      checkInsCount: readInt(source, [
        'checkInsCompleted',
        'check_ins_completed',
        'checkInsCount',
        'check_ins_count',
        'totalCheckIns',
        'total_check_ins',
        'count',
      ]),
      averageMood: readDouble(source, [
        'averageMood',
        'avgMood',
        'moodAverage',
        'mood_avg',
        'average_mood',
      ]),
      averageStress: readDouble(source, [
        'averageStress',
        'avgStress',
        'stressAverage',
        'stress_avg',
        'average_stress',
      ]),
      averageSleep: readDouble(source, [
        'averageSleep',
        'avgSleep',
        'sleepAverage',
        'sleep_avg',
        'average_sleep',
      ]),
      riskLevel: riskLevel,
      summary: readString(source, ['summary', 'overview']),
      insight: readString(source, ['insight', 'message', 'recommendation']),
      moodTrend: moodTrend,
      raw: payload,
    );
  }

  String get displaySummary {
    if (summary.isNotEmpty) return summary;
    if (insight.isNotEmpty) return insight;
    if (riskLevel.isNotEmpty) return 'Risk level: $riskLevel';
    return '';
  }
}

class InvitePreviewModel {
  const InvitePreviewModel({
    required this.valid,
    required this.email,
    required this.clinicName,
    required this.message,
    required this.raw,
  });

  final bool valid;
  final String email;
  final String clinicName;
  final String message;
  final Map<String, dynamic> raw;

  factory InvitePreviewModel.fromJson(Map<String, dynamic> json) {
    final payload = unwrapApiPayload(json);
    return InvitePreviewModel(
      valid: readBool(payload, ['valid', 'isValid', 'is_valid'], fallback: json['success'] == true),
      email: readString(payload, ['email']),
      clinicName: readString(payload, ['clinicName', 'clinic_name', 'clinic']),
      message: readString(payload, ['message', 'error']),
      raw: payload,
    );
  }
}

class TelehealthSessionModel {
  const TelehealthSessionModel({
    required this.provider,
    required this.joinUrl,
    required this.status,
    required this.raw,
  });

  final String provider;
  final String joinUrl;
  final String status;
  final Map<String, dynamic> raw;

  factory TelehealthSessionModel.fromJson(Map<String, dynamic> json) {
    final payload = unwrapApiPayload(json);
    return TelehealthSessionModel(
      provider: readString(payload, ['provider', 'platform', 'type']),
      joinUrl: readString(payload, ['joinUrl', 'join_url', 'url', 'meetingUrl']),
      status: readString(payload, ['status', 'state']),
      raw: payload,
    );
  }
}
