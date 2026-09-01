import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';

class ExecuteSubstitution implements UseCase<void, SubstitutionParams> {
  final IShiftRepository repository;

  ExecuteSubstitution(this.repository);

  @override
  Future<Either<Failure, void>> call(SubstitutionParams params) async {
    return await repository.executeSubstitution(
      shiftId: params.shiftId,
      originalNeighborId: params.originalNeighborId,
      substituteNeighborId: params.substituteNeighborId,
      effectiveProfile: params.effectiveProfile,
    );
  }
}

class SubstitutionParams extends Equatable {
  final String shiftId;
  final String originalNeighborId;
  final String? substituteNeighborId;
  final OperationalProfile effectiveProfile;

  const SubstitutionParams({
    required this.shiftId,
    required this.originalNeighborId,
    this.substituteNeighborId,
    required this.effectiveProfile,
  });

  @override
  List<Object?> get props => [shiftId, originalNeighborId, substituteNeighborId, effectiveProfile];
}
