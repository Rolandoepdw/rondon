import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/utils/app_logger.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';

class BaseSquadRepositoryImpl implements IBaseSquadRepository {
  final AppDatabase appDatabase;

  BaseSquadRepositoryImpl({required this.appDatabase});

  @override
  Future<Either<Failure, List<BaseSquadEntity>>> getAllSquads() async {
    try {
      final db = await appDatabase.database;
      AppLogger.read('SQUADS', 'Fetching all base squads');
      final squadsMaps = await db.query('base_squads', orderBy: 'name ASC');
      List<BaseSquadEntity> squads = [];
      
      for (var map in squadsMaps) {
        final squadId = map['id'] as String;
        final neighborMaps = await db.query('neighbors', where: 'base_squad_id = ?', whereArgs: [squadId]);
        final members = neighborMaps.map((n) => NeighborEntity.fromMap(n)).toList();
        
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
    try {
      final db = await appDatabase.database;
      AppLogger.read('SQUADS', 'Fetching squad by ID: $id');
      final result = await db.query('base_squads', where: 'id = ?', whereArgs: [id]);
      if (result.isEmpty) return const Right(null);

      final squadMap = result.first;
      final squadId = squadMap['id'] as String;
      final neighborMaps = await db.query('neighbors', where: 'base_squad_id = ?', whereArgs: [squadId]);
      final members = neighborMaps.map((n) => NeighborEntity.fromMap(n)).toList();

      final squad = BaseSquadEntity(
        id: squadId,
        name: squadMap['name'] as String,
        shiftTemplateId: squadMap['shift_template_id'] as String?,
        members: List<NeighborEntity>.from(members),
      );

      return Right(squad);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createSquad(BaseSquadEntity squad) async {
    try {
      final db = await appDatabase.database;
      AppLogger.create('SQUADS', 'Creating squad: ${squad.name}');
      await db.insert('base_squads', {
        'id': squad.id,
        'name': squad.name,
        'shift_template_id': squad.shiftTemplateId,
      });
      for (var member in squad.members) {
        await db.update('neighbors', {'base_squad_id': squad.id}, where: 'id = ?', whereArgs: [member.id]);
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSquad(BaseSquadEntity squad) async {
    try {
      final db = await appDatabase.database;
      AppLogger.update('SQUADS', 'Updating squad ID: ${squad.id}');
      await db.update(
        'base_squads',
        {
          'name': squad.name,
          'shift_template_id': squad.shiftTemplateId,
        },
        where: 'id = ?',
        whereArgs: [squad.id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSquad(String id) async {
    try {
      final db = await appDatabase.database;
      AppLogger.delete('SQUADS', 'Deleting squad ID: $id');
      await db.transaction((txn) async {
        await txn.update('neighbors', {'base_squad_id': null}, where: 'base_squad_id = ?', whereArgs: [id]);
        await txn.delete('base_squads', where: 'id = ?', whereArgs: [id]);
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addNeighborToSquad(String neighborId, String squadId) async {
    try {
      final db = await appDatabase.database;
      AppLogger.update('SQUADS', 'Adding neighbor $neighborId to squad $squadId');
      await db.update('neighbors', {'base_squad_id': squadId}, where: 'id = ?', whereArgs: [neighborId]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeNeighborFromSquad(String neighborId) async {
    try {
      final db = await appDatabase.database;
      AppLogger.update('SQUADS', 'Removing neighbor $neighborId from squad');
      await db.update('neighbors', {'base_squad_id': null}, where: 'id = ?', whereArgs: [neighborId]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
