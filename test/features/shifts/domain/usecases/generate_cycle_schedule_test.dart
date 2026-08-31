import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/generate_cycle_schedule.dart';

class MockNeighborRepository extends Mock implements INeighborRepository {}
class MockBaseSquadRepository extends Mock implements IBaseSquadRepository {}
class MockShiftTemplateRepository extends Mock implements IShiftTemplateRepository {}
class MockShiftRepository extends Mock implements IShiftRepository {}
class MockSettingsRepository extends Mock implements ISettingsRepository {}

void main() {
  late GenerateCycleSchedule usecase;
  late MockNeighborRepository mockNeighborRepository;
  late MockBaseSquadRepository mockBaseSquadRepository;
  late MockShiftTemplateRepository mockShiftTemplateRepository;
  late MockShiftRepository mockShiftRepository;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockNeighborRepository = MockNeighborRepository();
    mockBaseSquadRepository = MockBaseSquadRepository();
    mockShiftTemplateRepository = MockShiftTemplateRepository();
    mockShiftRepository = MockShiftRepository();
    mockSettingsRepository = MockSettingsRepository();

    usecase = GenerateCycleSchedule(
      neighborRepository: mockNeighborRepository,
      squadRepository: mockBaseSquadRepository,
      templateRepository: mockShiftTemplateRepository,
      shiftRepository: mockShiftRepository,
      settingsRepository: mockSettingsRepository,
    );

    // Default setups
    when(() => mockSettingsRepository.getMinDaysBetweenShifts())
        .thenAnswer((_) async => const Right(3));
    
    // Register fallback for capture
    registerFallbackValue(const []);
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

  final n1 = NeighborEntity(
    id: 'n1',
    fullName: 'Active Neighbor',
    gender: Gender.masculino,
    operationalProfile: OperationalProfile.activo,
    balance: 0,
    isActive: true,
  );

  final n2 = NeighborEntity(
    id: 'n2',
    fullName: 'Support Neighbor',
    gender: Gender.femenino,
    operationalProfile: OperationalProfile.apoyo,
    balance: 0,
    isActive: true,
  );

  test('should generate shifts and call save on repository', () async {
    // Arrange
    when(() => mockShiftTemplateRepository.getActiveTemplates())
        .thenAnswer((_) async => Right([t1]));
    when(() => mockBaseSquadRepository.getAllSquads())
        .thenAnswer((_) async => const Right([]));
    when(() => mockNeighborRepository.getAllNeighbors(onlyActive: any(named: 'onlyActive')))
        .thenAnswer((_) async => Right([n1, n2]));
    when(() => mockShiftRepository.getLastCompletedShiftDate(any(), any()))
        .thenAnswer((_) async => const Right(null));
    when(() => mockShiftRepository.saveGeneratedShifts(any()))
        .thenAnswer((_) async => const Right(null));

    final params = GenerateParams(
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 1),
    );

    // Act
    final result = await usecase(params);

    // Assert
    expect(result, const Right(null));
    verify(() => mockShiftRepository.saveGeneratedShifts(any())).called(1);
    
    final captured = verify(() => mockShiftRepository.saveGeneratedShifts(captureAny())).captured.first as List<ScheduledShiftEntity>;
    expect(captured.length, 1);
    expect(captured.first.assignments.length, 2);
  });

  test('should respect rest period invariant', () async {
    // Arrange
    // Neighbor n1 worked on Sept 29. Generating for Oct 1 (only 2 days difference). minDays = 3.
    // n1 should NOT be assigned.
    when(() => mockShiftTemplateRepository.getActiveTemplates())
        .thenAnswer((_) async => Right([t1]));
    when(() => mockBaseSquadRepository.getAllSquads())
        .thenAnswer((_) async => const Right([]));
    when(() => mockNeighborRepository.getAllNeighbors(onlyActive: any(named: 'onlyActive')))
        .thenAnswer((_) async => Right([n1]));
    when(() => mockShiftRepository.getLastCompletedShiftDate('n1', any()))
        .thenAnswer((_) async => Right(DateTime(2026, 9, 29)));
    when(() => mockShiftRepository.saveGeneratedShifts(any()))
        .thenAnswer((_) async => const Right(null));

    final params = GenerateParams(
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 1),
    );

    // Act
    await usecase(params);

    // Assert
    final captured = verify(() => mockShiftRepository.saveGeneratedShifts(captureAny())).captured.first as List<ScheduledShiftEntity>;
    expect(captured.first.assignments.isEmpty, true); // No neighbors eligible
  });

  test('should prioritize neighbors with debt (Fair-Share)', () async {
    // Arrange
    final nDebt = NeighborEntity(
      id: 'n_debt',
      fullName: 'Debtor',
      gender: Gender.masculino,
      operationalProfile: OperationalProfile.activo,
      balance: -2,
      isActive: true,
    );

    when(() => mockShiftTemplateRepository.getActiveTemplates())
        .thenAnswer((_) async => Right([t1])); // Quota is 2
    when(() => mockBaseSquadRepository.getAllSquads())
        .thenAnswer((_) async => const Right([]));
    when(() => mockNeighborRepository.getAllNeighbors(onlyActive: any(named: 'onlyActive')))
        .thenAnswer((_) async => Right([n1, n2, nDebt])); // 3 candidates for 2 slots
    when(() => mockShiftRepository.getLastCompletedShiftDate(any(), any()))
        .thenAnswer((_) async => const Right(null));
    when(() => mockShiftRepository.saveGeneratedShifts(any()))
        .thenAnswer((_) async => const Right(null));

    final params = GenerateParams(
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 1),
    );

    // Act
    await usecase(params);

    // Assert
    final captured = verify(() => mockShiftRepository.saveGeneratedShifts(captureAny())).captured.first as List<ScheduledShiftEntity>;
    final assignedIds = captured.first.assignments.map((a) => a.neighborId).toList();
    
    expect(assignedIds.contains('n_debt'), true); // Debtor must be assigned first
  });

  test('should ensure security requirement (min ACTIVE profiles)', () async {
    // Arrange
    // t1 requires 1 ACTIVE. Slot 1 is support n2. 
    // Even if n1 is second, he MUST be assigned to meet security.
    final tSecurity = ShiftTemplateEntity(
      id: 'ts',
      name: 'Secure Turn',
      startTime: '22:00',
      endTime: '02:00',
      allowedGender: AllowedGenderPolicy.mixto,
      targetQuota: 1, // Only 1 slot
      minActiveProfiles: 1, // MUST BE ACTIVE
      displayOrder: 1,
      isActive: true,
    );

    when(() => mockShiftTemplateRepository.getActiveTemplates())
        .thenAnswer((_) async => Right([tSecurity]));
    when(() => mockBaseSquadRepository.getAllSquads())
        .thenAnswer((_) async => const Right([]));
    // n2 is support, n1 is active.
    when(() => mockNeighborRepository.getAllNeighbors(onlyActive: any(named: 'onlyActive')))
        .thenAnswer((_) async => Right([n2, n1])); 
    
    when(() => mockShiftRepository.getLastCompletedShiftDate(any(), any()))
        .thenAnswer((_) async => const Right(null));
    when(() => mockShiftRepository.saveGeneratedShifts(any()))
        .thenAnswer((_) async => const Right(null));

    final params = GenerateParams(
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 1),
    );

    // Act
    await usecase(params);

    // Assert
    final captured = verify(() => mockShiftRepository.saveGeneratedShifts(captureAny())).captured.first as List<ScheduledShiftEntity>;
    // Should have picked n1 (ACTIVE) instead of n2 (SUPPORT) even if order was n2, n1.
    // In our implementation, we fill quota first, then check security.
    // Since quota is 1, it picks first eligible (n2). Then checks security. 
    // activeCount (0) < 1. It replaces support with active.
    expect(captured.first.assignments.first.neighborId, 'n1');
  });
}
