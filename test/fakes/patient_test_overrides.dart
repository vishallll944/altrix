import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:altrix/features/patient/data/models/patient_models.dart';
import 'package:altrix/features/patient/presentation/providers/patient_providers.dart';

final _fakeAppointment = AppointmentModel(
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
);

final _fakeDashboard = DashboardModel(
  nextAppointment: _fakeAppointment,
  upcomingAppointments: const [],
  reminders: const [
    DashboardItem(
      title: 'Complete PHQ-9 before Friday',
      body: '',
      time: '',
      isUnread: true,
    ),
  ],
  notifications: const [],
  pendingTasks: const [
    DashboardItem(
      title: 'Complete PHQ-9 before Friday',
      body: '',
      time: '',
      isUnread: true,
    ),
  ],
  unreadMessages: 1,
  unreadNotifications: 2,
  pendingForms: 1,
  upcomingAppointmentsCount: 1,
  clinicName: 'Mindaptix',
  headline: '',
  checkInStreak: 3,
  todayCheckInCompleted: false,
  todayMood: null,
  todayStress: null,
  todaySleep: null,
  latestMood: 7,
  latestStress: 4,
  latestSleep: 8,
  weeklyCheckInsCompleted: 2,
  weeklyAverageMood: 7,
  weeklyAverageStress: 4,
  weeklyAverageSleep: 7.5,
  recommendedWellnessTool: 'mindfulness',
  safetyPlanAvailable: true,
  safetyPlanSigned: false,
  raw: const {'source': 'test'},
);

List<Override> patientTestOverrides() {
  return [
    dashboardProvider.overrideWith((ref) async => _fakeDashboard),
    appointmentsProvider.overrideWith((ref) async => [_fakeAppointment]),
    conversationsProvider.overrideWith((ref) async => const []),
    checkInsProvider.overrideWith((ref) async => const []),
    progressProvider.overrideWith(
      (ref) async => const ProgressModel(
        streak: 3,
        longestStreak: 5,
        checkInsCount: 2,
        averageMood: 7,
        averageStress: 4,
        averageSleep: 7.5,
        riskLevel: 'low',
        summary: '',
        insight: '',
        moodTrend: [6, 7, 8, 7],
        raw: {'source': 'test'},
      ),
    ),
  ];
}
