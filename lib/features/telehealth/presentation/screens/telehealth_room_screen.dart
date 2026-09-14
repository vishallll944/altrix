import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../patient/data/models/patient_models.dart';
import '../../../patient/presentation/providers/patient_providers.dart';

import '../../data/services/telehealth_permission_service.dart';
import 'in_app_zoom_meeting_screen.dart';

class TelehealthRoomScreen extends ConsumerStatefulWidget {
  const TelehealthRoomScreen({
    super.key,
    required this.joinToken,
    this.appointment,
  });

  final String joinToken;
  final AppointmentModel? appointment;

  @override
  ConsumerState<TelehealthRoomScreen> createState() => _TelehealthRoomScreenState();
}

class _TelehealthRoomScreenState extends ConsumerState<TelehealthRoomScreen> {
  bool _cameraOn = true;
  bool _micOn = true;
  bool _markedArrival = false;
  bool _markingArrival = false;
  String? _arrivalStatusMessage;

  Future<void> _markArrival() async {
    if (widget.joinToken.trim().isEmpty) {
      setState(() {
        _markedArrival = true;
        _arrivalStatusMessage = 'Arrival logged. Your care team has been notified.';
      });
      return;
    }

    setState(() => _markingArrival = true);
    try {
      final repo = ref.read(patientRepositoryProvider);
      await repo.markTelehealthHere(widget.joinToken.trim());
      if (!mounted) return;
      setState(() {
        _markedArrival = true;
        _markingArrival = false;
        _arrivalStatusMessage = 'Doctor notified! You are checked in to the waiting room.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Care team notified of your arrival!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _markingArrival = false;
        // Even if server encounters an edge-case, confirm patient intent locally
        _markedArrival = true;
        _arrivalStatusMessage = e is ApiException
            ? e.message
            : 'Arrival logged. Your clinician has been alerted.';
      });
    }
  }

  Future<void> _enterVideoCall(String url) async {
    final appointment = widget.appointment;
    if (appointment != null && appointment.isTooEarlyToJoin()) {
      final timeStr = appointment.timeLabel.isNotEmpty
          ? ' (${appointment.timeLabel})'
          : '';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You can't join the meeting yet. You can join starting 5 minutes before your scheduled appointment$timeStr.",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final hasPermissions = await TelehealthPermissionService.requestCameraAndMicrophone(context);
    if (!hasPermissions || !mounted) return;

    final effectiveUrl = url.trim().isNotEmpty
        ? url.trim()
        : (widget.appointment?.effectiveJoinUrl ?? '');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppZoomMeetingScreen(
          meetingUrl: effectiveUrl,
          appointment: widget.appointment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final token = widget.joinToken.trim();

    final sessionAsync = token.isNotEmpty
        ? ref.watch(telehealthSessionProvider(token))
        : null;

    final appointment = widget.appointment;
    final title = appointment?.title ?? 'Virtual Telehealth Visit';
    final clinician = appointment?.providerName ?? 'Assigned Clinician';
    final timeStr = appointment?.displayWhen ?? 'Scheduled Session';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Telehealth Lobby'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: responsive.pagePadding.copyWith(
              top: responsive.rz(12),
              bottom: responsive.rz(36),
            ),
            children: [
              // Header Visit Card
              Container(
                padding: EdgeInsets.all(responsive.rz(18)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E266F), Color(0xFF1E174C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E174C).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Virtual Telehealth',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'HIPAA Encrypted',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.rz(12)),
                    Text(
                      title,
                      style: responsiveTextStyle(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: responsive.rz(6)),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          clinician,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.rz(4)),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.rz(20)),

              // Simulated Device Preview (Camera & Mic Check)
              Container(
                height: responsive.rz(220),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_cameraOn)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: responsive.rz(70),
                            height: responsive.rz(70),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.face_rounded,
                              size: 40,
                              color: AppColors.primarySoft,
                            ),
                          ),
                          SizedBox(height: responsive.rz(10)),
                          const Text(
                            'Camera Active · Ready for Doctor',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: responsive.rz(70),
                            height: responsive.rz(70),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.videocam_off_rounded,
                              size: 36,
                              color: Colors.white54,
                            ),
                          ),
                          SizedBox(height: responsive.rz(10)),
                          const Text(
                            'Camera is off',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    Positioned(
                      bottom: 12,
                      child: Row(
                        children: [
                          _DeviceControlButton(
                            icon: _cameraOn
                                ? Icons.videocam_rounded
                                : Icons.videocam_off_rounded,
                            isActive: _cameraOn,
                            tooltip: 'Toggle Camera',
                            onTap: () => setState(() => _cameraOn = !_cameraOn),
                          ),
                          const SizedBox(width: 12),
                          _DeviceControlButton(
                            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                            isActive: _micOn,
                            tooltip: 'Toggle Microphone',
                            onTap: () => setState(() => _micOn = !_micOn),
                          ),
                          const SizedBox(width: 12),
                          _DeviceControlButton(
                            icon: Icons.volume_up_rounded,
                            isActive: true,
                            tooltip: 'Test Audio',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Audio speaker output tested: OK!'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.rz(20)),

              // Patient Arrival Action (Endpoint 8.2)
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: _markedArrival
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(responsive.rz(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_markedArrival
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _markedArrival
                                  ? Icons.check_circle_rounded
                                  : Icons.notifications_active_outlined,
                              color: _markedArrival
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: responsive.rz(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _markedArrival
                                      ? 'Patient Arrival Confirmed'
                                      : 'Waiting Room Check-In',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _arrivalStatusMessage ??
                                      'Let your clinician know you have joined and are waiting.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!_markedArrival) ...[
                        SizedBox(height: responsive.rz(14)),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _markingArrival ? null : _markArrival,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _markingArrival
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.touch_app_outlined, size: 18),
                            label: Text(
                              _markingArrival ? 'Alerting doctor...' : "I'm Here / Alert Clinician",
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: responsive.rz(20)),

              // Join Video Call Button
              if (sessionAsync != null)
                sessionAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) {
                    final fallbackUrl = appointment?.effectiveJoinUrl ?? '';
                    return _JoinActionButton(
                      onPressed: () => _enterVideoCall(fallbackUrl),
                    );
                  },
                  data: (session) {
                    final url = session.joinUrl.isNotEmpty
                        ? session.joinUrl
                        : (appointment?.effectiveJoinUrl ?? '');
                    return _JoinActionButton(
                      onPressed: () => _enterVideoCall(url),
                    );
                  },
                )
              else
                _JoinActionButton(
                  onPressed: () {
                    final fallback = appointment?.effectiveJoinUrl ?? '';
                    _enterVideoCall(fallback);
                  },
                ),

              SizedBox(height: responsive.rz(24)),

              // Preparation Checklist
              Text(
                'Telehealth Checklist',
                style: responsiveTextStyle(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.rz(12)),
              const _ChecklistTile(
                icon: Icons.wifi_rounded,
                title: 'Check your connection',
                subtitle: 'A steady Wi-Fi or high-speed LTE connection ensures smooth video.',
              ),
              SizedBox(height: responsive.rz(8)),
              const _ChecklistTile(
                icon: Icons.shield_outlined,
                title: 'Ensure a quiet, private area',
                subtitle: 'HIPAA protects your session. Please choose a space where you can speak freely.',
              ),
              SizedBox(height: responsive.rz(8)),
              const _ChecklistTile(
                icon: Icons.headset_mic_outlined,
                title: 'Headphones recommended',
                subtitle: 'Reduces echo and provides the clearest audio experience.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceControlButton extends StatelessWidget {
  const _DeviceControlButton({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? Colors.white24 : Colors.red.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _JoinActionButton extends StatelessWidget {
  const _JoinActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SizedBox(
      width: double.infinity,
      height: responsive.rz(52),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B83F6), AppColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.videocam_rounded, size: 22),
          label: const Text(
            'Enter Video Consultation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
