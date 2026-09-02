import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
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
      throw ApiException(apiErrorMessage(json) ?? 'Login failed');
    }

    final payload = unwrapApiPayload(json);

    return LoginResponse(
      token: payload['token'] as String,
      client: ClientModel.fromJson(clientJsonFromPayload(payload)),
    );
  }
}
