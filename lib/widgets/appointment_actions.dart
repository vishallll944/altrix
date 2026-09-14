import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/patient/data/models/patient_models.dart';

import '../features/telehealth/presentation/screens/telehealth_room_screen.dart';

Future<void> openAppointmentJoin(
  BuildContext context,
  AppointmentModel appointment,
) async {
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
