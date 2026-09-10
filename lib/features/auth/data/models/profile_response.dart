import '../../../../core/network/api_response.dart';
import 'client_model.dart';

class ProfileResponse {
  const ProfileResponse({required this.client});

  final ClientModel client;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    requireApiSuccess(json, 'Could not load profile');

    final payload = unwrapApiPayload(json);

    return ProfileResponse(
      client: ClientModel.fromJson(clientJsonFromPayload(payload)),
    );
  }
}
