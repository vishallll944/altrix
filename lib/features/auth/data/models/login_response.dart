import '../../../../core/network/api_exception.dart';
import 'client_model.dart';

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.client,
  });

  final String token;
  final ClientModel client;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw ApiException(
        json['error'] as String? ?? 'Login failed',
      );
    }

    return LoginResponse(
      token: json['token'] as String,
      client: ClientModel.fromJson(json['client'] as Map<String, dynamic>),
    );
  }
}
