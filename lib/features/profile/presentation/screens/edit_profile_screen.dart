import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                if (user != null) ...[
                  SizedBox(height: responsive.rz(20)),
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
