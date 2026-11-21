import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/execute_substitution.dart';

class MockShiftRepository extends Mock implements IShiftRepository {}

void main() {
  late ExecuteSubstitution usecase;
  late MockShiftRepository mockShiftRepository;

  setUpAll(() {
    registerFallbackValue(OperationalProfile.active);
  });

  setUp(() {
    mockShiftRepository = MockShiftRepository();
    usecase = ExecuteSubstitution(mockShiftRepository);
  });

  test('should call executeSubstitution on repository with correct params', () async {
    // Arrange
    const shiftId = 'shift-1';
    const originalNeighborId = 'neighbor-1';
    const substituteNeighborId = 'neighbor-2';
    const effectiveProfile = OperationalProfile.active;

    when(() => mockShiftRepository.executeSubstitution(
          shiftId: any(named: 'shiftId'),
          originalNeighborId: any(named: 'originalNeighborId'),
          substituteNeighborId: any(named: 'substituteNeighborId'),
          effectiveProfile: any(named: 'effectiveProfile'),
        )).thenAnswer((_) async => const Right(null));

    // Act
    final result = await usecase(const SubstitutionParams(
      shiftId: shiftId,
      originalNeighborId: originalNeighborId,
      substituteNeighborId: substituteNeighborId,
      effectiveProfile: effectiveProfile,
    ));

    // Assert
    expect(result, const Right(null));
    verify(() => mockShiftRepository.executeSubstitution(
          shiftId: shiftId,
          originalNeighborId: originalNeighborId,
          substituteNeighborId: substituteNeighborId,
          effectiveProfile: effectiveProfile,
        )).called(1);
  });
}
