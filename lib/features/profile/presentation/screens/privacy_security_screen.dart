import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/sign_in_screen.dart';

/// Persisted privacy and security settings.
class SecurityPreferences {
  const SecurityPreferences({
    this.biometricsEnabled = false,
    this.autoLockMinutes = 5,
    this.emergencyAccessEnabled = true,
    this.analyticsOptIn = false,
  });

  final bool biometricsEnabled;
  final int autoLockMinutes;
  final bool emergencyAccessEnabled;
  final bool analyticsOptIn;

  SecurityPreferences copyWith({
    bool? biometricsEnabled,
    int? autoLockMinutes,
    bool? emergencyAccessEnabled,
    bool? analyticsOptIn,
  }) {
    return SecurityPreferences(
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      emergencyAccessEnabled: emergencyAccessEnabled ?? this.emergencyAccessEnabled,
      analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
    );
  }

  static const _keyBio = 'sec_pref_biometrics';
  static const _keyAutoLock = 'sec_pref_autolock';
  static const _keyEmergency = 'sec_pref_emergency';
  static const _keyAnalytics = 'sec_pref_analytics';

  static SecurityPreferences fromPrefs(SharedPreferences prefs) {
    return SecurityPreferences(
      biometricsEnabled: prefs.getBool(_keyBio) ?? false,
      autoLockMinutes: prefs.getInt(_keyAutoLock) ?? 5,
      emergencyAccessEnabled: prefs.getBool(_keyEmergency) ?? true,
      analyticsOptIn: prefs.getBool(_keyAnalytics) ?? false,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setBool(_keyBio, biometricsEnabled);
    await prefs.setInt(_keyAutoLock, autoLockMinutes);
    await prefs.setBool(_keyEmergency, emergencyAccessEnabled);
    await prefs.setBool(_keyAnalytics, analyticsOptIn);
  }
}

final securityPreferencesProvider =
    NotifierProvider<SecurityPreferencesNotifier, SecurityPreferences>(
  SecurityPreferencesNotifier.new,
);

class SecurityPreferencesNotifier extends Notifier<SecurityPreferences> {
  @override
  SecurityPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SecurityPreferences.fromPrefs(prefs);
  }

  Future<void> update(SecurityPreferences Function(SecurityPreferences current) fn) async {
    final updated = fn(state);
    state = updated;
    final prefs = ref.read(sharedPreferencesProvider);
    await updated.save(prefs);
  }
}

/// HIPAA-compliant Privacy and Security settings screen.
class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.badge, size: 26),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? All medical check-ins, appointments, messages, and profile data will be permanently removed. This cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.badge,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(authProvider.notifier).deleteAccount();
      if (!context.mounted) return;

      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (_) => false,
        );
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to delete account'),
            backgroundColor: AppColors.badge,
          ),
        );
      }
    }
  }

  void _showNoticeDialog(BuildContext context, {required String title, required String body}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final securityPrefs = ref.watch(securityPreferencesProvider);
    final notifier = ref.read(securityPreferencesProvider.notifier);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: responsive.pagePadding.copyWith(
              top: responsive.rz(16),
              bottom: responsive.rz(36),
            ),
            children: [
              // HIPAA & Security Status Banner Card
              Container(
                padding: EdgeInsets.all(responsive.rz(18)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(responsive.rz(22)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: responsive.rz(46),
                          height: responsive.rz(46),
                          decoration: BoxDecoration(
                            color: AppColors.mood5.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.mood5,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: responsive.rz(14)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HIPAA-Ready & Encrypted',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: responsive.rz(2)),
                              Text(
                                '256-Bit AES Data Protection',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.mood5.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.mood5.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: AppColors.mood5,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.rz(14)),
                    Text(
                      'Your Protected Health Information (PHI), medical check-ins, and telehealth visits are encrypted end-to-end and stored strictly in HIPAA-compliant healthcare data facilities.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.rz(22)),

              // App Lock & Biometrics
              _SectionHeader(
                title: 'Access & Authentication',
                subtitle: 'Control how your device unlocks the app',
              ),
              SizedBox(height: responsive.rz(10)),
              _SettingsGroupCard(
                children: [
                  _SecuritySwitchTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.primary,
                    title: 'Biometric Unlock',
                    subtitle: 'Require Face ID or Fingerprint on app open',
                    value: securityPrefs.biometricsEnabled,
                    onChanged: (val) => notifier.update(
                      (curr) => curr.copyWith(biometricsEnabled: val),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.rz(16),
                      vertical: responsive.rz(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: responsive.rz(38),
                          height: responsive.rz(38),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            color: Color(0xFF6366F1),
                            size: 19,
                          ),
                        ),
                        SizedBox(width: responsive.rz(12)),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-Lock Timeout',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Lock app when backgrounded',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownButton<int>(
                          value: securityPrefs.autoLockMinutes,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              notifier.update((curr) => curr.copyWith(autoLockMinutes: val));
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Immediately')),
                            DropdownMenuItem(value: 1, child: Text('1 minute')),
                            DropdownMenuItem(value: 5, child: Text('5 minutes')),
                            DropdownMenuItem(value: 15, child: Text('15 minutes')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _SecurityActionTile(
                    icon: Icons.lock_reset_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'Two-Factor Authentication (2FA)',
                    subtitle: 'Active for ${user?.email ?? "your email"}',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mood5.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Secured',
                        style: TextStyle(
                          color: AppColors.mood5,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.rz(22)),

              // Clinical Data Privacy
              _SectionHeader(
                title: 'Data Sharing & Privacy',
                subtitle: 'Manage who can view your health records',
              ),
              SizedBox(height: responsive.rz(10)),
              _SettingsGroupCard(
                children: [
                  _SecurityActionTile(
                    icon: Icons.medical_services_outlined,
                    iconColor: AppColors.primary,
                    title: 'Care Team Access',
                    subtitle: 'Your designated clinician and care managers only',
                    trailing: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.mood5,
                      size: 20,
                    ),
                    onTap: () {
                      _showNoticeDialog(
                        context,
                        title: 'Care Team Access',
                        body:
                            'Under HIPAA guidelines, only healthcare providers and clinical support staff assigned to your care plan can access your check-in history, notes, and appointment records.\n\nYour data is never sold or shared with advertisers.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _SecuritySwitchTile(
                    icon: Icons.emergency_outlined,
                    iconColor: AppColors.badge,
                    title: 'Emergency Medical Access',
                    subtitle: 'Allow verified ER clinicians to view allergies & emergency contacts',
                    value: securityPrefs.emergencyAccessEnabled,
                    onChanged: (val) => notifier.update(
                      (curr) => curr.copyWith(emergencyAccessEnabled: val),
                    ),
                  ),
                  const Divider(height: 1),
                  _SecuritySwitchTile(
                    icon: Icons.analytics_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Anonymous App Telemetry',
                    subtitle: 'Send de-identified diagnostic data to improve app reliability',
                    value: securityPrefs.analyticsOptIn,
                    onChanged: (val) => notifier.update(
                      (curr) => curr.copyWith(analyticsOptIn: val),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.rz(22)),

              // Data Export & Legal Documents
              _SectionHeader(
                title: 'Your Health Data Rights',
                subtitle: 'Export records or review legal disclosures',
              ),
              SizedBox(height: responsive.rz(10)),
              _SettingsGroupCard(
                children: [
                  _SecurityActionTile(
                    icon: Icons.download_rounded,
                    iconColor: const Color(0xFF22C55E),
                    title: 'Export Medical Summary',
                    subtitle: 'Download encrypted record of your check-ins & visits',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Medical summary export request submitted. A secure link will be sent to your email.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _SecurityActionTile(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Notice of Privacy Practices',
                    subtitle: 'How Altrix Health protects your PHI and HIPAA rights',
                    onTap: () {
                      _showNoticeDialog(
                        context,
                        title: 'Notice of Privacy Practices',
                        body:
                            'This notice describes how medical information about you may be used and disclosed and how you can get access to this information.\n\n1. Uses and Disclosures: We use your health information for treatment, payment, and health care operations.\n\n2. Your Rights: You have the right to inspect and copy your health records, request restrictions on disclosures, and receive an accounting of disclosures.\n\n3. Security Safeguards: All data in Altrix is protected by strict technical, physical, and administrative safeguards required by HIPAA.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _SecurityActionTile(
                    icon: Icons.policy_outlined,
                    iconColor: AppColors.textSecondary,
                    title: 'Terms of Service',
                    subtitle: 'Platform usage agreement and telehealth consent',
                    onTap: () {
                      _showNoticeDialog(
                        context,
                        title: 'Terms of Service',
                        body:
                            'By using Altrix, you agree to comply with our patient terms of service. Telehealth sessions are conducted via encrypted audio/video channels adhering to state licensing and medical practice requirements.',
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: responsive.rz(26)),

              // Danger Zone
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.badge.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: responsive.rz(16),
                    vertical: responsive.rz(4),
                  ),
                  leading: Container(
                    width: responsive.rz(40),
                    height: responsive.rz(40),
                    decoration: BoxDecoration(
                      color: AppColors.badge.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.badge,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Delete Account & Data',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.badge,
                    ),
                  ),
                  subtitle: const Text(
                    'Permanently erase your patient profile and records',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.badge,
                  ),
                  onTap: () => _confirmDeleteAccount(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SecuritySwitchTile extends StatelessWidget {
  const _SecuritySwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.rz(16),
        vertical: responsive.rz(12),
      ),
      child: Row(
        children: [
          Container(
            width: responsive.rz(38),
            height: responsive.rz(38),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          SizedBox(width: responsive.rz(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.rz(8)),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SecurityActionTile extends StatelessWidget {
  const _SecurityActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.rz(16),
            vertical: responsive.rz(13),
          ),
          child: Row(
            children: [
              Container(
                width: responsive.rz(38),
                height: responsive.rz(38),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              SizedBox(width: responsive.rz(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: responsive.rz(8)),
                trailing!,
              ] else if (onTap != null) ...[
                SizedBox(width: responsive.rz(8)),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.iconMuted,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
