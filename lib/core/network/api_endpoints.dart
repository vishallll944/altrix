class ApiEndpoints {
  const ApiEndpoints._();

  // Auth & onboarding (no token)
  static const patientLogin = '/api/patient/login';
  static const patientInvitePreview = '/api/patient/invite/preview';
  static const patientInviteAccept = '/api/patient/invite/accept';

  // Profile & home
  static const patientMe = '/api/patient/me';
  static const patientDashboard = '/api/patient/dashboard';

  // Appointments
  static const patientAppointments = '/api/patient/appointments';
  static String patientAppointment(String id) => '/api/patient/appointments/$id';
  static String patientAppointmentCancel(String id) =>
      '/api/patient/appointments/$id/cancel';
  static String patientAppointmentReschedule(String id) =>
      '/api/patient/appointments/$id/reschedule';

  // Doctors & slots
  static const patientDoctors = '/api/patient/doctors';
  static String patientDoctorAvailability(String doctorId) =>
      '/api/patient/doctors/$doctorId/availability';

  // Messages
  static const patientConversations = '/api/patient/conversations';
  static String patientConversationMessages(String conversationId) =>
      '/api/patient/conversations/$conversationId/messages';
  static String patientMessageRead(String messageId) =>
      '/api/patient/messages/$messageId/read';

  // Check-ins & progress
  static const patientCheckIns = '/api/patient/check-ins';
  static const patientProgress = '/api/patient/progress';

  // Telehealth (join token auth)
  static String telehealthJoin(String joinToken) => '/api/telehealth/join/$joinToken';
  static const telehealthSignal = '/api/telehealth/signal';
}
