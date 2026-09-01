import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/get_replacement_candidates.dart';

class MockNeighborRepository extends Mock implements INeighborRepository {}
class MockShiftRepository extends Mock implements IShiftRepository {}
class MockSettingsRepository extends Mock implements ISettingsRepository {}

void main() {
  late GetReplacementCandidates usecase;
  late MockNeighborRepository mockNeighborRepository;
  late MockShiftRepository mockShiftRepository;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockNeighborRepository = MockNeighborRepository();
    mockShiftRepository = MockShiftRepository();
    mockSettingsRepository = MockSettingsRepository();

    usecase = GetReplacementCandidates(
      neighborRepository: mockNeighborRepository,
      shiftRepository: mockShiftRepository,
      settingsRepository: mockSettingsRepository,
    );

    when(() => mockSettingsRepository.getMinDaysBetweenShifts())
        .thenAnswer((_) async => const Right(3));
  });

  final t1 = ShiftTemplateEntity(
    id: 't1',
    name: 'Turno 1',
    startTime: '22:00',
    endTime: '02:00',
    allowedGender: AllowedGenderPolicy.mixto,
    targetQuota: 2,
    minActiveProfiles: 1,
    displayOrder: 1,
    isActive: true,
  );

  final shift = ScheduledShiftEntity(
    id: 's1',
    date: DateTime(2026, 10, 10),
    shiftTemplateId: 't1',
    template: t1,
    status: ShiftStatus.planificado,
  );

  final n1 = NeighborEntity(
    id: 'n1',
    fullName: 'Neighbor 1',
    gender: Gender.masculino,
    operationalProfile: OperationalProfile.activo,
    balance: 0,
    isActive: true,
  );

  final n2 = NeighborEntity(
    id: 'n2',
    fullName: 'Neighbor 2',
    gender: Gender.masculino,
    operationalProfile: OperationalProfile.activo,
    balance: -1,
    isActive: true,
  );

  test('should exclude the original neighbor being replaced', () async {
    // Arrange
    when(() => mockNeighborRepository.getAllNeighbors(onlyActive: true))
        .thenAnswer((_) async => Right([n1, n2]));
    when(() => mockShiftRepository.getShiftById('s1'))
        .thenAnswer((_) async => Right(shift));
    when(() => mockShiftRepository.getLastCompletedShiftDate(any(), any()))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await usecase(const ReplacementParams(shiftId: 's1', originalNeighborId: 'n1'));

    // Assert
    final candidates = result.getOrElse(() => []);
    expect(candidates.any((c) => c.neighbor.id == 'n1'), false);
    expect(candidates.length, 1);
    expect(candidates.first.neighbor.id, 'n2');
  });

  test('should prioritize candidates by debt (Fair-Share)', () async {
    // Arrange
    final n3 = NeighborEntity(
      id: 'n3',
      fullName: 'Neighbor 3',
      gender: Gender.masculino,
      operationalProfile: OperationalProfile.activo,
      balance: -2, // More debt than n2 (-1)
      isActive: true,
    );

    when(() => mockNeighborRepository.getAllNeighbors(onlyActive: true))
        .thenAnswer((_) async => Right([n1, n2, n3]));
    when(() => mockShiftRepository.getShiftById('s1'))
        .thenAnswer((_) async => Right(shift));
    when(() => mockShiftRepository.getLastCompletedShiftDate(any(), any()))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await usecase(const ReplacementParams(shiftId: 's1', originalNeighborId: 'n1'));

    // Assert
    final candidates = result.getOrElse(() => []);
    expect(candidates[0].neighbor.id, 'n3'); // Most debt first
    expect(candidates[1].neighbor.id, 'n2');
  });
}
