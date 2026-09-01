import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/entities/balance_ledger_record.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';
import 'package:rondon/features/neighbors/data/datasources/neighbor_local_datasource.dart';
import 'package:rondon/features/neighbors/data/models/neighbor_model.dart';

class NeighborRepositoryImpl implements INeighborRepository {
  final NeighborLocalDataSource localDataSource;

  NeighborRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<NeighborEntity>>> getAllNeighbors({bool onlyActive = true}) async {
    try {
      final neighbors = await localDataSource.getAllNeighbors(onlyActive: onlyActive);
      return Right(List<NeighborEntity>.from(neighbors));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NeighborEntity?>> getNeighborById(String id) async {
    try {
      final neighbor = await localDataSource.getNeighborById(id);
      return Right(neighbor);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createNeighbor(NeighborEntity neighbor) async {
    try {
      await localDataSource.createNeighbor(NeighborModel.fromEntity(neighbor));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNeighbor(NeighborEntity neighbor) async {
    try {
      await localDataSource.updateNeighbor(NeighborModel.fromEntity(neighbor));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNeighbor(String id) async {
    try {
      await localDataSource.deleteNeighbor(id);
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
      await localDataSource.updateBalance(
        neighborId: neighborId,
        delta: delta,
        reason: reason,
        shiftId: shiftId,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BalanceLedgerRecordEntity>>> getLedgerHistory(String neighborId) async {
    try {
      final results = await localDataSource.getLedgerHistory(neighborId);
      final list = results.map((map) => BalanceLedgerRecordEntity(
        id: map['id'],
        neighborId: map['neighbor_id'],
        scheduledShiftId: map['scheduled_shift_id'],
        delta: map['delta'],
        reason: LedgerReason.fromString(map['reason']),
        notes: map['notes'],
        createdAt: DateTime.parse(map['created_at']),
      )).toList();
      return Right(list);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
