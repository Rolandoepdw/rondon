import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/audit_shift_attendance.dart';

class MockShiftRepository extends Mock implements IShiftRepository {}

void main() {
  late AuditShiftAttendance usecase;
  late MockShiftRepository mockShiftRepository;

  setUp(() {
    mockShiftRepository = MockShiftRepository();
    usecase = AuditShiftAttendance(mockShiftRepository);
  });

  test('should call auditShiftAttendance on repository with correct params', () async {
    // Arrange
    final attendanceMap = {
      'n1': AttendanceStatus.presente,
      'n2': AttendanceStatus.falta,
    };
    
    when(() => mockShiftRepository.auditShiftAttendance(
      shiftId: any(named: 'shiftId'),
      attendanceMap: any(named: 'attendanceMap'),
      notes: any(named: 'notes'),
    )).thenAnswer((_) async => const Right(null));

    // Act
    final result = await usecase(AuditParams(shiftId: 's1', attendanceMap: attendanceMap, notes: 'Some notes'));

    // Assert
    expect(result, const Right(null));
    verify(() => mockShiftRepository.auditShiftAttendance(
      shiftId: 's1',
      attendanceMap: attendanceMap,
      notes: 'Some notes',
    )).called(1);
  });
}
