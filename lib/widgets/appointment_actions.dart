import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/patient/data/models/patient_models.dart';
import '../features/telehealth/data/services/telehealth_permission_service.dart';
import '../features/telehealth/presentation/screens/telehealth_room_screen.dart';

Future<void> openAppointmentJoin(
  BuildContext context,
  AppointmentModel appointment, {
  DateTime? currentTime,
  Future<bool> Function()? permissionRequester,
}) async {
  if (appointment.isTooEarlyToJoin(currentTime)) {
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

  if (appointment.isMeetingConcluded(currentTime)) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This meeting has already ended.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
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

  // Request Camera & Microphone permissions before opening video room
  final hasPermissions = await TelehealthPermissionService.requestCameraAndMicrophone(
    context,
    overrideRequester: permissionRequester,
  );
  if (!hasPermissions || !context.mounted) return;

  if (appointment.joinToken.isNotEmpty || appointment.effectiveJoinUrl.isNotEmpty) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelehealthRoomScreen(
          joinToken: appointment.joinToken,
          appointment: appointment,
        ),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Virtual visit link is not ready yet. Please check closer to your appointment.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> openAppointmentDirections(
  BuildContext context,
  AppointmentModel appointment,
) async {
  final location = appointment.location;
  if (location.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No location available for this visit')),
    );
    return;
  }

  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
  );

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open maps')),
    );
  }
}
