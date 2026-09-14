import '../../../../core/network/api_response.dart';
import '../../domain/entities/user.dart';

class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.addressLine1 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.avatarUrl = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String avatarUrl;

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    final addressObj = json['address'];
    final addressMap = addressObj is Map<String, dynamic>
        ? addressObj
        : (addressObj is Map ? Map<String, dynamic>.from(addressObj) : null);
    final addressString = addressObj is String ? addressObj : null;

    final ecObj = json['emergencyContact'] ?? json['emergency_contact'];
    final ecMap = ecObj is Map<String, dynamic>
        ? ecObj
        : (ecObj is Map ? Map<String, dynamic>.from(ecObj) : null);

    return ClientModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ??
          json['fullName'] as String? ??
          json['full_name'] as String? ??
          '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? json['phoneNumber'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ??
          addressString ??
          addressMap?['line1'] as String? ??
          addressMap?['street'] as String? ??
          addressMap?['address'] as String? ??
          '',
      city: json['city'] as String? ??
          addressMap?['city'] as String? ??
          '',
      state: json['state'] as String? ??
          addressMap?['state'] as String? ??
          '',
      postalCode: json['postalCode'] as String? ??
          json['zipCode'] as String? ??
          json['zip'] as String? ??
          addressMap?['postalCode'] as String? ??
          addressMap?['zipCode'] as String? ??
          addressMap?['zip'] as String? ??
          '',
      emergencyContactName: json['emergencyContactName'] as String? ??
          json['emergency_contact_name'] as String? ??
          ecMap?['name'] as String? ??
          '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ??
          json['emergency_contact_phone'] as String? ??
          ecMap?['phone'] as String? ??
          ecMap?['phoneNumber'] as String? ??
          '',
      avatarUrl: resolveMediaUrl(
        readString(json, [
          'avatarUrl',
          'avatar_url',
          'avatar',
          'image',
          'imageUrl',
          'image_url',
          'photoUrl',
          'photo_url',
          'picture',
        ]),
      ),
    );
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      addressLine1: addressLine1,
      city: city,
      state: state,
      postalCode: postalCode,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      avatarUrl: avatarUrl,
    );
  }
}
