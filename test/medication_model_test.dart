import 'package:flutter_test/flutter_test.dart';
import 'package:altrix/features/patient/data/models/medication_model.dart';

void main() {
  group('MedicationScheduleModel backend integration', () {
    test('correctly parses todayDoses with boolean taken: true', () {
      final json = {
        'id': 'cmu40fp5d0002qf41dqwmcqd7',
        'medicationName': 'Aripiprazole (Abilify)',
        'dosage': '50mg',
        'instructions': 'Three times daily.',
        'doseTimes': ['08:00', '13:00', '20:00'],
        'startDate': '2026-09-16T11:21:17.329Z',
        'endDate': '2026-10-16T11:21:17.329Z',
        'isActive': true,
        'todayDoses': [
          {'time': '08:00', 'taken': true, 'takenAt': '2026-09-16T11:38:26.388Z', 'skipped': false},
          {'time': '13:00', 'taken': true, 'takenAt': '2026-09-16T11:38:22.871Z', 'skipped': false},
          {'time': '20:00', 'taken': false, 'takenAt': null, 'skipped': false}
        ]
      };

      final model = MedicationScheduleModel.fromJson(json);

      expect(model.id, 'cmu40fp5d0002qf41dqwmcqd7');
      expect(model.medicationName, 'Aripiprazole (Abilify)');
      expect(model.doseTimes, ['08:00', '13:00', '20:00']);
      expect(model.todayLogs.length, 3);

      expect(model.statusFor('08:00'), MedicationDoseStatus.taken);
      expect(model.statusFor('13:00'), MedicationDoseStatus.taken);
      expect(model.statusFor('20:00'), MedicationDoseStatus.pending);

      expect(model.takenCount, 2);
      expect(model.pendingCount, 1);
    });

    test('optimistic update with withUpdatedLog marks dose taken', () {
      final json = {
        'id': 'med_1',
        'medicationName': 'Paracetamol',
        'dosage': '500mg',
        'instructions': 'Take after food',
        'doseTimes': ['08:00', '13:00'],
        'startDate': '2026-09-16',
        'endDate': '2026-10-16',
        'isActive': true,
        'todayDoses': [
          {'time': '08:00', 'taken': false, 'skipped': false}
        ]
      };

      final model = MedicationScheduleModel.fromJson(json);
      expect(model.statusFor('08:00'), MedicationDoseStatus.pending);

      final updated = model.withUpdatedLog('08:00', MedicationDoseStatus.taken);
      expect(updated.statusFor('08:00'), MedicationDoseStatus.taken);
      expect(updated.takenCount, 1);
    });
  });
}
