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
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (addressLine1 != null && addressLine1!.trim().isNotEmpty)
        'addressLine1': addressLine1!.trim(),
      if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
      if (state != null && state!.trim().isNotEmpty) 'state': state!.trim(),
      if (postalCode != null && postalCode!.trim().isNotEmpty)
        'postalCode': postalCode!.trim(),
      if (emergencyContactName != null && emergencyContactName!.trim().isNotEmpty)
        'emergencyContactName': emergencyContactName!.trim(),
      if (emergencyContactPhone != null && emergencyContactPhone!.trim().isNotEmpty)
        'emergencyContactPhone': emergencyContactPhone!.trim(),
    };
  }
}
