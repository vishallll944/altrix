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
    requireApiSuccess(json, 'Login failed');

    final payload = unwrapApiPayload(json);
    final token = readString(
      payload,
      ['token', 'accessToken', 'access_token', 'jwt', 'bearerToken'],
      fallback: readString(
        json,
        ['token', 'accessToken', 'access_token', 'jwt', 'bearerToken'],
      ),
    );

    if (token.isEmpty) {
      throw const ApiException('No authentication token received from server');
    }

    return LoginResponse(
      token: token,
      client: ClientModel.fromJson(clientJsonFromPayload(payload)),
    );
  }
}
