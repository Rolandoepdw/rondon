import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/neighbors/data/datasources/base_squad_local_datasource.dart';
import 'package:rondon/features/neighbors/data/models/neighbor_model.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';

class BaseSquadRepositoryImpl implements IBaseSquadRepository {
  final BaseSquadLocalDataSource localDataSource;

  BaseSquadRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<BaseSquadEntity>>> getAllSquads() async {
    try {
      final squadsMaps = await localDataSource.getAllSquads();
      List<BaseSquadEntity> squads = [];
      
      for (var map in squadsMaps) {
        final squadId = map['id'] as String;
        final neighborMaps = await localDataSource.getNeighborsBySquadId(squadId);
        final members = neighborMaps.map((n) => NeighborModel.fromMap(n)).toList();
        
        squads.add(BaseSquadEntity(
          id: squadId,
          name: map['name'] as String,
          shiftTemplateId: map['shift_template_id'] as String?,
          members: List<NeighborEntity>.from(members),
        ));
      }
      return Right(squads);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BaseSquadEntity?>> getSquadById(String id) async {
    // Implementación similar a getAll pero filtrado
    // Por simplicidad para el MVP usamos getAll y filtramos en dominio si es necesario
    // o implementamos directo si se requiere performance.
    return const Left(DatabaseFailure('Not implemented'));
  }

  @override
  Future<Either<Failure, void>> createSquad(BaseSquadEntity squad) async {
    try {
      await localDataSource.createSquad(squad.id, squad.name, squad.shiftTemplateId);
      // Opcionalmente asignar miembros si la entidad los trae
      for (var member in squad.members) {
        await localDataSource.setNeighborSquad(member.id, squad.id);
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSquad(BaseSquadEntity squad) async {
    try {
      await localDataSource.updateSquad(squad.id, squad.name, squad.shiftTemplateId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSquad(String id) async {
    try {
      await localDataSource.deleteSquad(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addNeighborToSquad(String neighborId, String squadId) async {
    try {
      await localDataSource.setNeighborSquad(neighborId, squadId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeNeighborFromSquad(String neighborId) async {
    try {
      await localDataSource.setNeighborSquad(neighborId, null);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
