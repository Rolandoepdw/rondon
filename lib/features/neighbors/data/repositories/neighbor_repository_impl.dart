import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/utils/app_logger.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/entities/balance_ledger_record.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

class NeighborRepositoryImpl implements INeighborRepository {
  final AppDatabase appDatabase;

  NeighborRepositoryImpl({required this.appDatabase});

  @override
  Future<Either<Failure, List<NeighborEntity>>> getAllNeighbors({bool onlyActive = true}) async {
    try {
      final db = await appDatabase.database;
      AppLogger.read('NEIGHBORS', 'Fetching all neighbors (onlyActive: $onlyActive)');
      final result = await db.query(
        'neighbors',
        where: onlyActive ? 'is_active = 1' : null,
        orderBy: 'full_name ASC',
      );
      final neighbors = result.map((map) => NeighborEntity.fromMap(map)).toList();
      return Right(neighbors);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NeighborEntity?>> getNeighborById(String id) async {
    try {
      final db = await appDatabase.database;
      AppLogger.read('NEIGHBORS', 'Fetching neighbor by ID: $id');
      final result = await db.query('neighbors', where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) {
        return Right(NeighborEntity.fromMap(result.first));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createNeighbor(NeighborEntity neighbor) async {
    try {
      final db = await appDatabase.database;
      AppLogger.create('NEIGHBORS', 'Creating neighbor: ${neighbor.fullName}');
      await db.insert('neighbors', neighbor.toMap());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNeighbor(NeighborEntity neighbor) async {
    try {
      final db = await appDatabase.database;
      AppLogger.update('NEIGHBORS', 'Updating neighbor ID: ${neighbor.id}');
      await db.update('neighbors', neighbor.toMap(), where: 'id = ?', whereArgs: [neighbor.id]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNeighbor(String id) async {
    try {
      final db = await appDatabase.database;
      AppLogger.delete('NEIGHBORS', 'Deleting neighbor ID: $id');
      await db.delete('neighbors', where: 'id = ?', whereArgs: [id]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBalance({
    required String neighborId,
    required int delta,
    required LedgerReason reason,
    String? shiftId,
    String? notes,
  }) async {
    try {
      final db = await appDatabase.database;
      AppLogger.create('LEDGER', 'Updating balance for neighbor $neighborId by $delta (Reason: ${reason.value})');
      await db.transaction((txn) async {
        await txn.insert('balance_ledger_records', {
          'id': const Uuid().v4(),
          'neighbor_id': neighborId,
          'scheduled_shift_id': shiftId,
          'delta': delta,
          'reason': reason.value,
          'notes': notes,
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BalanceLedgerRecordEntity>>> getLedgerHistory(String neighborId) async {
    try {
      final db = await appDatabase.database;
      AppLogger.read('LEDGER', 'Fetching ledger history for neighbor: $neighborId');
      final results = await db.query(
        'balance_ledger_records',
        where: 'neighbor_id = ?',
        whereArgs: [neighborId],
        orderBy: 'created_at DESC',
      );
      final list = results.map((map) => BalanceLedgerRecordEntity(
        id: map['id'] as String,
        neighborId: map['neighbor_id'] as String,
        scheduledShiftId: map['scheduled_shift_id'] as String?,
        delta: map['delta'] as int,
        reason: LedgerReason.fromString(map['reason'] as String),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      )).toList();
      return Right(list);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
