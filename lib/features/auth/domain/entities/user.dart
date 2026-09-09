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
}
