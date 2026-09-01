class OtpRequest {
  const OtpRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}
