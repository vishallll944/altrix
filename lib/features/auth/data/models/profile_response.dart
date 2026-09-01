import '../../../../core/network/api_exception.dart';
import 'client_model.dart';

class ProfileResponse {
  const ProfileResponse({required this.client});

  final ClientModel client;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw ApiException(
        json['error'] as String? ?? 'Could not load profile',
      );
    }

    return ProfileResponse(
      client: ClientModel.fromJson(json['client'] as Map<String, dynamic>),
    );
  }
}
