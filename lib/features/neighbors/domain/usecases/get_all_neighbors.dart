import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

class GetAllNeighbors implements UseCase<List<NeighborEntity>, bool> {
  final INeighborRepository repository;

  GetAllNeighbors(this.repository);

  @override
  Future<Either<Failure, List<NeighborEntity>>> call(bool onlyActive) async {
    return await repository.getAllNeighbors(onlyActive: onlyActive);
  }
}
