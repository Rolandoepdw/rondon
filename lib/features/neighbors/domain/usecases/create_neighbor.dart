import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

class CreateNeighbor implements UseCase<void, NeighborEntity> {
  final INeighborRepository repository;

  CreateNeighbor(this.repository);

  @override
  Future<Either<Failure, void>> call(NeighborEntity neighbor) async {
    return await repository.createNeighbor(neighbor);
  }
}
