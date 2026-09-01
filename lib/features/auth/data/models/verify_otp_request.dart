class VerifyOtpRequest {
  const VerifyOtpRequest({
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
    };
  }
}
