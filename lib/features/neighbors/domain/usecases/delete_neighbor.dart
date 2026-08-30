import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

class DeleteNeighbor implements UseCase<void, String> {
  final INeighborRepository repository;

  DeleteNeighbor(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteNeighbor(id);
  }
}
