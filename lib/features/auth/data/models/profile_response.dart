import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import 'client_model.dart';

class ProfileResponse {
  const ProfileResponse({required this.client});

  final ClientModel client;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw ApiException(apiErrorMessage(json) ?? 'Could not load profile');
    }

    final payload = unwrapApiPayload(json);

    return ProfileResponse(
      client: ClientModel.fromJson(clientJsonFromPayload(payload)),
    );
  }
}
