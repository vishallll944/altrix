import '../models/patient_models.dart';

const _inactiveStatuses = {'cancelled', 'canceled', 'completed', 'no_show', 'no-show'};

List<AppointmentModel> sortUpcomingAppointments(List<AppointmentModel> appointments) {
  final upcoming = appointments
      .where((item) => !_inactiveStatuses.contains(item.status.toLowerCase()))
      .toList()
    ..sort((a, b) {
      final aDate = a.sortDateTime;
      final bDate = b.sortDateTime;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

  return upcoming;
}

AppointmentModel? nextAppointment(List<AppointmentModel> appointments) {
  final sorted = sortUpcomingAppointments(appointments);
  if (sorted.isEmpty) return null;
  return sorted.first;
}

List<AppointmentModel> homeUpcomingAppointments(List<AppointmentModel> appointments) {
  final sorted = sortUpcomingAppointments(appointments);
  if (sorted.length <= 1) return const [];
  return sorted.skip(1).take(3).toList();
}
