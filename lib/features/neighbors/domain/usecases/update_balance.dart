import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

class UpdateBalance implements UseCase<void, UpdateBalanceParams> {
  final INeighborRepository repository;

  UpdateBalance(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateBalanceParams params) async {
    return await repository.updateBalance(
      neighborId: params.neighborId,
      delta: params.delta,
      reason: params.reason,
      shiftId: params.shiftId,
      notes: params.notes,
    );
  }
}

class UpdateBalanceParams extends Equatable {
  final String neighborId;
  final int delta;
  final LedgerReason reason;
  final String? shiftId;
  final String? notes;

  const UpdateBalanceParams({
    required this.neighborId,
    required this.delta,
    required this.reason,
    this.shiftId,
    this.notes,
  });

  @override
  List<Object?> get props => [neighborId, delta, reason, shiftId, notes];
}
