import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
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
      // Explícitamente convertimos a una lista de la interfaz base
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
}
