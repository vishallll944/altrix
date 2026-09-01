/// Central place for API route paths.
/// Update these when your backend contract is finalized.
class ApiEndpoints {
  const ApiEndpoints._();

  static const authLogin = '/auth/login';
  static const authForgotPassword = '/auth/forgot-password';
  static const authOtpSend = '/auth/otp/send';
  static const authOtpVerify = '/auth/otp/verify';
}
