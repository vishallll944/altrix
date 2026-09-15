import '../models/patient_models.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepository {
  const PatientRepository(this._remote);

  final PatientRemoteDataSource _remote;

  Future<InvitePreviewModel> previewInvite(String token) => _remote.previewInvite(token);

  Future<Map<String, dynamic>> getProfile() => _remote.getProfile();

  Future<Map<String, dynamic>> updateProfile({
    String? phone,
    String? addressLine1,
    String? city,
    String? state,
    String? postalCode,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) =>
      _remote.updateProfile(
        phone: phone,
        addressLine1: addressLine1,
        city: city,
        state: state,
        postalCode: postalCode,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );

  Future<DashboardModel> getDashboard() => _remote.getDashboard();

  Future<List<AppointmentModel>> getAppointments() => _remote.getAppointments();

  Future<AppointmentModel> getAppointment(String id) => _remote.getAppointment(id);

  Future<AppointmentModel> bookAppointment({
    required String clinicianId,
    required String type,
    required String date,
    required String startTime,
    String? endTime,
    required bool isVirtual,
  }) =>
      _remote.bookAppointment(
        clinicianId: clinicianId,
        type: type,
        date: date,
        startTime: startTime,
        endTime: endTime,
        isVirtual: isVirtual,
      );

  Future<AppointmentModel> cancelAppointment(String id) => _remote.cancelAppointment(id);

  Future<AppointmentModel> rescheduleAppointment({
    required String id,
    required String date,
    required String startTime,
    String? endTime,
    String? note,
  }) =>
      _remote.rescheduleAppointment(
        id: id,
        date: date,
        startTime: startTime,
        endTime: endTime,
        note: note,
      );

  Future<List<DoctorModel>> getDoctors() => _remote.getDoctors();

  Future<List<AvailabilitySlotModel>> getDoctorAvailability({
    required String doctorId,
    String? from,
    int? days,
  }) =>
      _remote.getDoctorAvailability(doctorId: doctorId, from: from, days: days);

  Future<List<ConversationModel>> getConversations() => _remote.getConversations();

  Future<ConversationModel> createConversation({
    required String topic,
    required String message,
  }) =>
      _remote.createConversation(topic: topic, message: message);

  Future<({String threadId, List<MessageModel> messages})> getPatientMessages({
    String? threadId,
  }) =>
      _remote.getPatientMessages(threadId: threadId);

  Future<MessageModel> sendPatientMessage({
    required String content,
    String? threadId,
  }) =>
      _remote.sendPatientMessage(content: content, threadId: threadId);

  Future<List<MessageModel>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getConversationMessages(
        conversationId: conversationId,
        page: page,
        limit: limit,
      );

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String message,
  }) =>
      _remote.sendMessage(conversationId: conversationId, message: message);

  Future<void> markMessageRead(String messageId) => _remote.markMessageRead(messageId);

  Future<List<CheckInModel>> getCheckIns({
    int? page,
    int limit = 20,
    int? skip,
    String? from,
    String? to,
  }) =>
      _remote.getCheckIns(
        page: page,
        limit: limit,
        skip: skip,
        from: from,
        to: to,
      );

  Future<CheckInModel> createCheckIn({
    required int mood,
    required int stress,
    int sleep = 7,
    String journal = 'Feeling much better today and rested well.',
  }) =>
      _remote.createCheckIn(
        mood: mood,
        stress: stress,
        sleep: sleep,
        journal: journal,
      );

  Future<ProgressModel> getProgress() => _remote.getProgress();

  Future<TelehealthSessionModel> getTelehealthSession(String joinToken) =>
      _remote.getTelehealthSession(joinToken);

  Future<Map<String, dynamic>> markTelehealthHere(String joinToken) =>
      _remote.markTelehealthHere(joinToken);

  Future<Map<String, dynamic>> pollTelehealthSignal({
    required String joinToken,
    int after = 0,
  }) =>
      _remote.pollTelehealthSignal(joinToken: joinToken, after: after);

  Future<Map<String, dynamic>> sendTelehealthSignal({
    required String joinToken,
    required String type,
    Map<String, dynamic>? data,
  }) =>
      _remote.sendTelehealthSignal(joinToken: joinToken, type: type, data: data);

  Future<List<PatientFormModel>> getForms({int page = 1, int limit = 20}) =>
      _remote.getForms(page: page, limit: limit);

  Future<PatientFormModel> getForm(String id) => _remote.getForm(id);

  Future<void> logout() => _remote.logout();

  Future<void> deleteAccount() => _remote.deleteAccount();

  Future<String?> uploadAvatar(String filePath) => _remote.uploadAvatar(filePath);

  Stream<Map<String, dynamic>> streamLiveMessages({
    required String threadId,
    required String token,
  }) =>
      _remote.streamLiveMessages(threadId: threadId, token: token);
}

