import 'package:uuid/uuid.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/neighbors/data/models/neighbor_model.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

abstract class NeighborLocalDataSource {
  Future<List<NeighborModel>> getAllNeighbors({bool onlyActive = true});
  Future<NeighborModel?> getNeighborById(String id);
  Future<void> createNeighbor(NeighborModel neighbor);
  Future<void> updateNeighbor(NeighborModel neighbor);
  Future<void> deleteNeighbor(String id);
  Future<void> updateBalance({
    required String neighborId,
    required int delta,
    required LedgerReason reason,
    String? shiftId,
    String? notes,
  });
}

class NeighborLocalDataSourceImpl implements NeighborLocalDataSource {
  final AppDatabase appDatabase;

  NeighborLocalDataSourceImpl({required this.appDatabase});

  @override
  Future<List<NeighborModel>> getAllNeighbors({bool onlyActive = true}) async {
    final db = await appDatabase.database;
    final result = await db.query(
      'neighbors',
      where: onlyActive ? 'is_active = 1' : null,
      orderBy: 'full_name ASC',
    );

    return result.map((map) => NeighborModel.fromMap(map)).toList();
  }

  @override
  Future<NeighborModel?> getNeighborById(String id) async {
    final db = await appDatabase.database;
    final result = await db.query(
      'neighbors',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return NeighborModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<void> createNeighbor(NeighborModel neighbor) async {
    final db = await appDatabase.database;
    await db.insert('neighbors', neighbor.toMap());
  }

  @override
  Future<void> updateNeighbor(NeighborModel neighbor) async {
    final db = await appDatabase.database;
    await db.update(
      'neighbors',
      neighbor.toMap(),
      where: 'id = ?',
      whereArgs: [neighbor.id],
    );
  }

  @override
  Future<void> deleteNeighbor(String id) async {
    final db = await appDatabase.database;
    await db.delete(
      'neighbors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateBalance({
    required String neighborId,
    required int delta,
    required LedgerReason reason,
    String? shiftId,
    String? notes,
  }) async {
    final db = await appDatabase.database;

    await db.transaction((txn) async {
      // 1. Obtener balance actual
      final neighborResult = await txn.query(
        'neighbors',
        columns: ['balance'],
        where: 'id = ?',
        whereArgs: [neighborId],
      );

      if (neighborResult.isEmpty) return;

      final currentBalance = neighborResult.first['balance'] as int;
      final newBalance = currentBalance + delta;

      // 2. Actualizar balance en tabla neighbors
      await txn.update(
        'neighbors',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [neighborId],
      );

      // 3. Registrar en ledger
      await txn.insert('balance_ledger_records', {
        'id': const Uuid().v4(),
        'neighbor_id': neighborId,
        'scheduled_shift_id': shiftId,
        'delta': delta,
        'reason': reason.value,
        'notes': notes,
      });
    });
  }
}
