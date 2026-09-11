class User {
  const User({
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

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? addressLine1,
    String? city,
    String? state,
    String? postalCode,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
