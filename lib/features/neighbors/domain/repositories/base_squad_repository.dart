import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';

abstract class IBaseSquadRepository {
  Future<Either<Failure, List<BaseSquadEntity>>> getAllSquads();
  Future<Either<Failure, BaseSquadEntity?>> getSquadById(String id);
  Future<Either<Failure, void>> createSquad(BaseSquadEntity squad);
  Future<Either<Failure, void>> updateSquad(BaseSquadEntity squad);
  Future<Either<Failure, void>> deleteSquad(String id);
  Future<Either<Failure, void>> addNeighborToSquad(String neighborId, String squadId);
  Future<Either<Failure, void>> removeNeighborFromSquad(String neighborId);
}
