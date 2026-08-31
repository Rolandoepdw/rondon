import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';

class GetAllSquads implements UseCase<List<BaseSquadEntity>, NoParams> {
  final IBaseSquadRepository repository;

  GetAllSquads(this.repository);

  @override
  Future<Either<Failure, List<BaseSquadEntity>>> call(NoParams params) async {
    return await repository.getAllSquads();
  }
}
