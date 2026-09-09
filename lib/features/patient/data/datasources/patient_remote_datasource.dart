import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../models/patient_models.dart';
import '../utils/appointment_utils.dart';

class PatientRemoteDataSource {
  const PatientRemoteDataSource(this._dio);

  final Dio _dio;

  void _ensureApiConfigured() {
    if (!Env.isApiConfigured) {
      throw const ApiException(
        'API URL is not configured yet. Add API_BASE_URL when your backend is ready.',
      );
    }
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    _ensureApiConfigured();
    try {
      final response = await call();
      final data = response.data;
      if (data == null) {
        throw const ApiException('Empty response from server');
      }
      requireApiSuccess(data);
      return data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<InvitePreviewModel> previewInvite(String token) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientInvitePreview,
        queryParameters: {'token': token},
      ),
    );
    return InvitePreviewModel.fromJson(data);
  }

  Future<DashboardModel> getDashboard() async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.patientDashboard),
    );
    return DashboardModel.fromJson(data);
  }

  Future<List<AppointmentModel>> getAppointments() async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.patientAppointments),
    );

    final rootData = data['data'];
    final List<Map<String, dynamic>> items;
    if (rootData is List) {
      items = asJsonMapList(rootData);
    } else {
      final payload = unwrapApiPayload(data);
      items = extractListFromPayload(payload, keys: const ['appointments', 'items']);
    }

    return sortUpcomingAppointments(
      items.map(AppointmentModel.fromJson).toList(),
    );
  }

  Future<AppointmentModel> getAppointment(String id) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.patientAppointment(id)),
    );
    final payload = unwrapApiPayload(data);
    final appointment = payload['appointment'];
    if (appointment is Map<String, dynamic>) {
      return AppointmentModel.fromJson(appointment);
    }
    return AppointmentModel.fromJson(payload);
  }

  Future<AppointmentModel> bookAppointment({
    required String clinicianId,
    required String type,
    required String date,
    required String startTime,
    String? endTime,
    required bool isVirtual,
  }) async {
    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientAppointments,
        data: {
          'clinicianId': clinicianId,
          'type': type,
          'date': date,
          'startTime': startTime,
          if (endTime != null) 'endTime': endTime,
          'isVirtual': isVirtual,
        },
      ),
    );
    final payload = unwrapApiPayload(data);
    final appointment = payload['appointment'];
    if (appointment is Map<String, dynamic>) {
      return AppointmentModel.fromJson(appointment);
    }
    return AppointmentModel.fromJson(payload);
  }

  Future<AppointmentModel> cancelAppointment(String id) async {
    final data = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.patientAppointmentCancel(id),
        data: const {},
      ),
    );
    final payload = unwrapApiPayload(data);
    final appointment = payload['appointment'];
    if (appointment is Map<String, dynamic>) {
      return AppointmentModel.fromJson(appointment);
    }
    return AppointmentModel.fromJson(payload);
  }

  Future<AppointmentModel> rescheduleAppointment({
    required String id,
    required String date,
    required String startTime,
    String? endTime,
    String? note,
  }) async {
    final data = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.patientAppointmentReschedule(id),
        data: {
          'date': date,
          'startTime': startTime,
          if (endTime != null) 'endTime': endTime,
          if (note != null) 'note': note,
        },
      ),
    );
    final payload = unwrapApiPayload(data);
    final appointment = payload['appointment'];
    if (appointment is Map<String, dynamic>) {
      return AppointmentModel.fromJson(appointment);
    }
    return AppointmentModel.fromJson(payload);
  }

  Future<List<DoctorModel>> getDoctors() async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.patientDoctors),
    );
    final payload = unwrapApiPayload(data);
    return extractListFromPayload(payload, keys: const ['doctors', 'items'])
        .map(DoctorModel.fromJson)
        .toList();
  }

  Future<List<AvailabilitySlotModel>> getDoctorAvailability({
    required String doctorId,
    String? from,
    int? days,
  }) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientDoctorAvailability(doctorId),
        queryParameters: {
          if (from != null) 'from': from,
          if (days != null) 'days': days,
        },
      ),
    );
    final payload = unwrapApiPayload(data);
    return extractListFromPayload(payload, keys: const ['slots', 'availability', 'items'])
        .map(AvailabilitySlotModel.fromJson)
        .toList();
  }

  Future<List<ConversationModel>> getConversations() async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.patientConversations),
    );
    final payload = unwrapApiPayload(data);
    return extractListFromPayload(payload, keys: const ['conversations', 'items'])
        .map(ConversationModel.fromJson)
        .toList();
  }

  Future<ConversationModel> createConversation({
    required String topic,
    required String message,
  }) async {
    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientConversations,
        data: {
          'topic': topic,
          'message': message,
        },
      ),
    );
    final payload = unwrapApiPayload(data);
    final conversation = payload['conversation'];
    if (conversation is Map<String, dynamic>) {
      return ConversationModel.fromJson(conversation);
    }
    return ConversationModel.fromJson(payload);
  }

  Future<List<MessageModel>> getConversationMessages({
    required String conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientConversationMessages(conversationId),
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      ),
    );
    final payload = unwrapApiPayload(data);
    return extractListFromPayload(payload, keys: const ['messages', 'items'])
        .map(MessageModel.fromJson)
        .toList();
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientConversationMessages(conversationId),
        data: {'message': message},
      ),
    );
    final payload = unwrapApiPayload(data);
    final item = payload['message'];
    if (item is Map<String, dynamic>) {
      return MessageModel.fromJson(item);
    }
    return MessageModel.fromJson(payload);
  }

  Future<void> markMessageRead(String messageId) async {
    await _request(
      () => _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.patientMessageRead(messageId),
        data: const {},
      ),
    );
  }

  Future<List<CheckInModel>> getCheckIns({
    int page = 1,
    int limit = 20,
    String? from,
    String? to,
  }) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientCheckIns,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      ),
    );
    final payload = unwrapApiPayload(data);
    return extractListFromPayload(payload, keys: const ['checkIns', 'check_ins', 'items'])
        .map(CheckInModel.fromJson)
        .toList();
  }

  Future<CheckInModel> createCheckIn({
    required int mood,
    required int stress,
    int? sleep,
    String? journal,
  }) async {
    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientCheckIns,
        data: {
          'mood': mood,
          'stress': stress,
          if (sleep != null) 'sleep': sleep,
          if (journal != null && journal.isNotEmpty) 'journal': journal,
        },
      ),
    );
    final payload = unwrapApiPayload(data);
    final item = payload['checkIn'] ?? payload['check_in'];
    if (item is Map<String, dynamic>) {
      return CheckInModel.fromJson(item);
    }
    return CheckInModel.fromJson(payload);
  }

  Future<ProgressModel> getProgress() async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.patientProgress),
    );
    return ProgressModel.fromJson(data);
  }

  Future<TelehealthSessionModel> getTelehealthSession(String joinToken) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.telehealthJoin(joinToken)),
    );
    return TelehealthSessionModel.fromJson(data);
  }

  Future<Map<String, dynamic>> markTelehealthHere(String joinToken) async {
    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.telehealthJoin(joinToken),
        data: const {'action': 'here'},
      ),
    );
    return unwrapApiPayload(data);
  }

  Future<Map<String, dynamic>> pollTelehealthSignal({
    required String joinToken,
    int after = 0,
  }) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.telehealthSignal,
        queryParameters: {
          'token': joinToken,
          'after': after,
        },
      ),
    );
    return unwrapApiPayload(data);
  }

  Future<Map<String, dynamic>> sendTelehealthSignal({
    required String joinToken,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.telehealthSignal,
        data: {
          'token': joinToken,
          'from': 'client',
          'type': type,
          'data': data ?? const {},
        },
      ),
    );
    return unwrapApiPayload(response);
  }

  Future<List<PatientFormModel>> getForms({
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientForms,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      ),
    );
    final payload = unwrapApiPayload(data);
    return extractListFromPayload(payload, keys: const ['forms', 'items'])
        .map(PatientFormModel.fromJson)
        .toList();
  }

  Future<PatientFormModel> getForm(String id) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiEndpoints.patientForm(id)),
    );
    final payload = unwrapApiPayload(data);
    final form = payload['form'];
    if (form is Map<String, dynamic>) {
      return PatientFormModel.fromJson(form);
    }
    return PatientFormModel.fromJson(payload);
  }
}
