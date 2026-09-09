class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.email,
    this.phone,
    this.addressLine1,
    this.city,
    this.state,
    this.postalCode,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  final String? email;
  final String? phone;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  Map<String, dynamic> toJson() {
    return {
      if (email != null && email!.isNotEmpty) 'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (addressLine1 != null && addressLine1!.isNotEmpty)
        'addressLine1': addressLine1,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (postalCode != null && postalCode!.isNotEmpty)
        'postalCode': postalCode,
      if (emergencyContactName != null && emergencyContactName!.isNotEmpty)
        'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty)
        'emergencyContactPhone': emergencyContactPhone,
    };
  }
}
