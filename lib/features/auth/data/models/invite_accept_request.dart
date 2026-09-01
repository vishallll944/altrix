class InviteAcceptRequest {
  const InviteAcceptRequest({
    required this.token,
    required this.password,
  });

  final String token;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'password': password,
    };
  }
}
