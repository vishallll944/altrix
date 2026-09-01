import 'user_model.dart';

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final UserModel user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
