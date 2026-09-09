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

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ??
          json['address'] as String? ??
          '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ??
          json['zipCode'] as String? ??
          json['zip'] as String? ??
          '',
      emergencyContactName: json['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
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
    );
  }
}
