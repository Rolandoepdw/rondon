import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';

class UpdateBaseSquad implements UseCase<void, BaseSquadEntity> {
  final IBaseSquadRepository repository;

  UpdateBaseSquad(this.repository);

  @override
  Future<Either<Failure, void>> call(BaseSquadEntity squad) async {
    return await repository.updateSquad(squad);
  }
}
