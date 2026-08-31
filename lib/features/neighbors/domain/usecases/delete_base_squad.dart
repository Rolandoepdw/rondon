import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';

class DeleteBaseSquad implements UseCase<void, String> {
  final IBaseSquadRepository repository;

  DeleteBaseSquad(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteSquad(id);
  }
}
