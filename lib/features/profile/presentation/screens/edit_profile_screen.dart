import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_buttons.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _saving = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.addressLine1 ?? '';
    _cityController.text = user?.city ?? '';
    _stateController.text = user?.state ?? '';
    _zipController.text = user?.postalCode ?? '';
    _emergencyNameController.text = user?.emergencyContactName ?? '';
    _emergencyPhoneController.text = user?.emergencyContactPhone ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showImageSourcePicker() {
    final responsive = context.responsive;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          responsive.rz(20),
          responsive.rz(24),
          responsive.rz(20),
          responsive.rz(28),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(responsive.rz(24)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Profile Photo',
                style: responsiveTextStyle(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.rz(6)),
              Text(
                'Upload a photo from your gallery or take a new one with your camera.',
                style: responsiveTextStyle(
                  context,
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: responsive.rz(20)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: responsive.rz(44),
                  height: responsive.rz(44),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(responsive.rz(12)),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                    size: responsive.rz(22),
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Select an existing image from your device',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: responsive.rz(8)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: responsive.rz(44),
                  height: responsive.rz(44),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(responsive.rz(12)),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: responsive.rz(22),
                  ),
                ),
                title: Text(
                  'Take a Photo',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Use your camera to capture a new photo',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _uploadingAvatar = true);

      final success = await ref
          .read(authProvider.notifier)
          .uploadAvatar(pickedFile.path);

      if (!mounted) return;
      setState(() => _uploadingAvatar = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to upload photo'),
            backgroundColor: AppColors.badge,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (err) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error choosing image: $err'),
          backgroundColor: AppColors.badge,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _enableInteractionValidation() {
    if (_autovalidateMode == AutovalidateMode.onUserInteraction) return;
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _enableInteractionValidation();
      return;
    }

    final user = ref.read(authProvider).user;
    final currentPhone = (user?.phone ?? '').trim();
    final currentAddress = (user?.addressLine1 ?? '').trim();
    final currentCity = (user?.city ?? '').trim();
    final currentState = (user?.state ?? '').trim();
    final currentZip = (user?.postalCode ?? '').trim();
    final currentEmName = (user?.emergencyContactName ?? '').trim();
    final currentEmPhone = (user?.emergencyContactPhone ?? '').trim();

    final newPhone = _phoneController.text.trim();
    final newAddress = _addressController.text.trim();
    final newCity = _cityController.text.trim();
    final newState = _stateController.text.trim();
    final newZip = _zipController.text.trim();
    final newEmName = _emergencyNameController.text.trim();
    final newEmPhone = _emergencyPhoneController.text.trim();

    // Sirf wahi fields bhejo jo change hui hain
    final phoneToSend = newPhone != currentPhone ? newPhone : null;
    final addressToSend = newAddress != currentAddress ? newAddress : null;
    final cityToSend = newCity != currentCity ? newCity : null;
    final stateToSend = newState != currentState ? newState : null;
    final zipToSend = newZip != currentZip ? newZip : null;
    final emNameToSend = newEmName != currentEmName ? newEmName : null;
    final emPhoneToSend = newEmPhone != currentEmPhone ? newEmPhone : null;

    final hasChanges = phoneToSend != null ||
        addressToSend != null ||
        cityToSend != null ||
        stateToSend != null ||
        zipToSend != null ||
        emNameToSend != null ||
        emPhoneToSend != null;

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);

    final success = await ref.read(authProvider.notifier).updateProfile(
          phone: phoneToSend,
          addressLine1: addressToSend,
          city: cityToSend,
          state: stateToSend,
          postalCode: zipToSend,
          emergencyContactName: emNameToSend,
          emergencyContactPhone: emPhoneToSend,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop();
      return;
    }

    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: ListView(
              padding: responsive.pagePadding.copyWith(
                top: responsive.rz(16),
                bottom: responsive.rz(28),
              ),
              children: [
                Text(
                  'Contact details',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.rz(6)),
                Text(
                  'Update the contact information your clinic has on file.',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 14.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: responsive.rz(20)),
                // Profile Avatar Photo Section with Camera / Gallery Picker
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9B93F8), AppColors.primary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: responsive.rz(46),
                              backgroundColor: AppColors.primary,
                              backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                                  ? NetworkImage(user!.avatarUrl)
                                  : null,
                              child: (user?.avatarUrl.isNotEmpty ?? false)
                                  ? null
                                  : Text(
                                      _initials(user?.name ?? 'Patient'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: responsive.rz(28),
                                      ),
                                    ),
                            ),
                          ),
                          if (_uploadingAvatar)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: AppColors.primary,
                              shape: const CircleBorder(),
                              elevation: 4,
                              child: InkWell(
                                onTap: _uploadingAvatar ? null : _showImageSourcePicker,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  padding: EdgeInsets.all(responsive.rz(9)),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: responsive.rz(18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.rz(8)),
                      TextButton.icon(
                        onPressed: _uploadingAvatar ? null : _showImageSourcePicker,
                        icon: Icon(
                          Icons.photo_camera_outlined,
                          size: responsive.rz(16),
                          color: AppColors.primary,
                        ),
                        label: Text(
                          _uploadingAvatar ? 'Uploading photo...' : 'Change profile photo',
                          style: responsiveTextStyle(
                            context,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (user != null) ...[
                  SizedBox(height: responsive.rz(12)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive.rz(16)),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(responsive.rz(18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name',
                          style: responsiveTextStyle(
                            context,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: responsive.rz(4)),
                        Text(
                          user.name,
                          style: responsiveTextStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (user.email.isNotEmpty) ...[
                          SizedBox(height: responsive.rz(12)),
                          Text(
                            'Email',
                            style: responsiveTextStyle(
                              context,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: responsive.rz(4)),
                          Text(
                            user.email,
                            style: responsiveTextStyle(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                SizedBox(height: responsive.rz(16)),
                AppTextField(
                  label: 'Phone',
                  controller: _phoneController,
                  hint: '555-1234',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  onChanged: (_) => _enableInteractionValidation(),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return 'Enter your phone number';
                    if (phone.length < 7) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: responsive.rz(24)),
                Text(
                  'Address',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.rz(12)),
                AppTextField(
                  label: 'Street address',
                  controller: _addressController,
                  hint: '123 Main St',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _enableInteractionValidation(),
                ),
                SizedBox(height: responsive.rz(12)),
                AppTextField(
                  label: 'City',
                  controller: _cityController,
                  hint: 'Baltimore',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _enableInteractionValidation(),
                ),
                SizedBox(height: responsive.rz(12)),
                AppTextField(
                  label: 'State',
                  controller: _stateController,
                  hint: 'MD',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _enableInteractionValidation(),
                ),
                SizedBox(height: responsive.rz(12)),
                AppTextField(
                  label: 'Postal code',
                  controller: _zipController,
                  hint: '21201',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _enableInteractionValidation(),
                ),
                SizedBox(height: responsive.rz(24)),
                Text(
                  'Emergency Contact',
                  style: responsiveTextStyle(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.rz(12)),
                AppTextField(
                  label: 'Contact name',
                  controller: _emergencyNameController,
                  hint: 'Jane Doe',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _enableInteractionValidation(),
                ),
                SizedBox(height: responsive.rz(12)),
                AppTextField(
                  label: 'Contact phone',
                  controller: _emergencyPhoneController,
                  hint: '+1 (555) 0101',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _enableInteractionValidation(),
                ),
                SizedBox(height: responsive.rz(28)),
                PrimaryButton(
                  label: 'Save changes',
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
