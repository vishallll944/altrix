class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.email,
    required this.phone,
  });

  final String email;
  final String phone;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
    };
  }
}
