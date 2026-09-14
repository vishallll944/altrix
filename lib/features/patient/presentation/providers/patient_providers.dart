import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/patient_remote_datasource.dart';
import '../../data/models/patient_models.dart';
import '../../data/repositories/patient_repository.dart';

final patientRemoteDataSourceProvider = Provider<PatientRemoteDataSource>((ref) {
  return PatientRemoteDataSource(ref.watch(dioProvider));
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(patientRemoteDataSourceProvider));
});

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  return ref.watch(patientRepositoryProvider).getDashboard();
});

final appointmentsProvider = FutureProvider<List<AppointmentModel>>((ref) async {
  return ref.watch(patientRepositoryProvider).getAppointments();
});

final doctorsProvider = FutureProvider.autoDispose<List<DoctorModel>>((ref) async {
  return ref.watch(patientRepositoryProvider).getDoctors();
});

final conversationsProvider =
    FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  return ref.watch(patientRepositoryProvider).getConversations();
});

final checkInsProvider = FutureProvider.autoDispose<List<CheckInModel>>((ref) async {
  return ref.watch(patientRepositoryProvider).getCheckIns(limit: 10);
});

final progressProvider = FutureProvider<ProgressModel>((ref) async {
  return ref.watch(patientRepositoryProvider).getProgress();
});

final invitePreviewProvider =
    FutureProvider.autoDispose.family<InvitePreviewModel, String>((ref, token) async {
  return ref.watch(patientRepositoryProvider).previewInvite(token);
});

final conversationMessagesProvider = FutureProvider.autoDispose
    .family<List<MessageModel>, String>((ref, conversationId) async {
  return ref.watch(patientRepositoryProvider).getConversationMessages(
        conversationId: conversationId,
      );
});

final doctorAvailabilityProvider = FutureProvider.autoDispose
    .family<List<AvailabilitySlotModel>, String>((ref, doctorId) async {
  return ref.watch(patientRepositoryProvider).getDoctorAvailability(doctorId: doctorId);
});

typedef AppointmentSlotQuery = ({String doctorId, String date});

final appointmentSlotsProvider = FutureProvider.autoDispose
    .family<List<AvailabilitySlotModel>, AppointmentSlotQuery>((
      ref,
      query,
    ) async {
      final slots = await ref
          .watch(patientRepositoryProvider)
          .getDoctorAvailability(
            doctorId: query.doctorId,
            from: query.date,
            days: 1,
          );
      return slots
          .where(
            (slot) =>
                slot.date == query.date &&
                slot.isAvailable &&
                RegExp(r'^\d{2}:\d{2}$').hasMatch(slot.startTime) &&
                RegExp(r'^\d{2}:\d{2}$').hasMatch(slot.endTime) &&
                slot.endTime.compareTo(slot.startTime) > 0,
          )
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    });

final telehealthSessionProvider = FutureProvider.autoDispose
    .family<TelehealthSessionModel, String>((ref, joinToken) async {
  return ref.watch(patientRepositoryProvider).getTelehealthSession(joinToken);
});

final formsProvider =
    FutureProvider.autoDispose<List<PatientFormModel>>((ref) async {
  return ref.watch(patientRepositoryProvider).getForms();
});

final formDetailProvider =
    FutureProvider.autoDispose.family<PatientFormModel, String>((ref, id) async {
  return ref.watch(patientRepositoryProvider).getForm(id);
});
