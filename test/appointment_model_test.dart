import 'package:flutter_test/flutter_test.dart';

import 'package:altrix/features/patient/data/models/patient_models.dart';

void main() {
  test('AppointmentModel parses joinUrl from appointments API payload', () {
    const payload = {
      'success': true,
      'data': {
        'appointments': [
          {
            'id': 'cmtiedwbm0001wc8cb356rgny',
            'type': 'Telehealth Check-in',
            'date': '2026-09-01',
            'startTime': '10:20',
            'endTime': '11:10',
            'startsAt': '2026-09-01T10:20:00.000Z',
            'endsAt': '2026-09-01T11:10:00.000Z',
            'status': 'confirmed',
            'isVirtual': true,
            'clinicianName': 'Clinic Admin',
            'joinUrl':
                'https://us05web.zoom.us/j/86415304776?pwd=ITzXgRub3xbm1cvJu9mWS8dcTyplLM.1',
          },
        ],
      },
    };

    final appointment = AppointmentModel.fromJson(
      (payload['data'] as Map<String, dynamic>)['appointments'][0]
          as Map<String, dynamic>,
    );

    expect(
      appointment.effectiveJoinUrl,
      'https://us05web.zoom.us/j/86415304776?pwd=ITzXgRub3xbm1cvJu9mWS8dcTyplLM.1',
    );
    expect(appointment.hasJoinLink, isTrue);
    expect(appointment.isVirtual, isTrue);
    expect(appointment.providerName, 'Clinic Admin');
  });
}
