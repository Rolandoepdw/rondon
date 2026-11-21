import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/messaging/domain/usecases/build_reminder_message.dart';

void main() {
  late BuildReminderMessage usecase;

  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
  });

  setUp(() {
    usecase = BuildReminderMessage();
  });

  final template = ShiftTemplateEntity(
    id: 't1',
    name: 'Turno 1',
    startTime: '22:00',
    endTime: '02:00',
    allowedGender: AllowedGenderPolicy.mixed,
    targetQuota: 2,
    minActiveProfiles: 1,
    displayOrder: 1,
    isActive: true,
  );

  final n1 = NeighborEntity(
    id: 'n1',
    fullName: 'Juan Pérez',
    gender: Gender.male,
    operationalProfile: OperationalProfile.active,
    balance: 0,
    isActive: true,
  );

  final n2 = NeighborEntity(
    id: 'n2',
    fullName: 'María García',
    gender: Gender.female,
    operationalProfile: OperationalProfile.support,
    balance: 0,
    isActive: true,
  );

  final shift = ScheduledShiftEntity(
    id: 's1',
    date: DateTime(2026, 10, 15),
    shiftTemplateId: 't1',
    template: template,
    status: ShiftStatus.planificado,
    assignments: [
      ShiftAssignmentEntity(
        id: 'a1',
        scheduledShiftId: 's1',
        neighborId: 'n1',
        neighbor: n1,
        isSubstitute: false,
        attendanceStatus: AttendanceStatus.pendiente,
        effectiveOperationalProfile: OperationalProfile.active,
        balanceImpacted: false,
      ),
      ShiftAssignmentEntity(
        id: 'a2',
        scheduledShiftId: 's1',
        neighborId: 'n2',
        neighbor: n2,
        isSubstitute: true,
        attendanceStatus: AttendanceStatus.pendiente,
        effectiveOperationalProfile: OperationalProfile.support,
        balanceImpacted: false,
      ),
    ],
  );

  test('should build correct individual reminder message', () {
    // Act
    final message = usecase(shift, shift.assignments[0]);

    // Assert
    expect(message.contains('Juan Pérez'), true);
    expect(message.contains('15'), true);
    expect(message.contains('octubre'), true);
    expect(message.contains('María García'), true);
    expect(message.contains('Titular'), true);
  });

  test('should build correct broadcast message', () {
    // Act
    final message = usecase.buildBroadcast(shift);

    // Assert
    expect(message.contains('Juan Pérez (Titular)'), true);
    expect(message.contains('María García (Refuerzo)'), true);
    expect(message.contains('22:00 a 02:00'), true);
  });
}
