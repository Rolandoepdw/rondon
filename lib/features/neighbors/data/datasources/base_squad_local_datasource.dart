import 'package:rondon/database/app_database.dart';

abstract class BaseSquadLocalDataSource {
  Future<List<Map<String, dynamic>>> getAllSquads();
  Future<List<Map<String, dynamic>>> getNeighborsBySquadId(String squadId);
  Future<void> createSquad(String id, String name, String? templateId);
  Future<void> updateSquad(String id, String name, String? templateId);
  Future<void> deleteSquad(String id);
  Future<void> setNeighborSquad(String neighborId, String? squadId);
}

class BaseSquadLocalDataSourceImpl implements BaseSquadLocalDataSource {
  final AppDatabase appDatabase;

  BaseSquadLocalDataSourceImpl({required this.appDatabase});

  @override
  Future<List<Map<String, dynamic>>> getAllSquads() async {
    final db = await appDatabase.database;
    return await db.query('base_squads', orderBy: 'name ASC');
  }

  @override
  Future<List<Map<String, dynamic>>> getNeighborsBySquadId(String squadId) async {
    final db = await appDatabase.database;
    return await db.query('neighbors', where: 'base_squad_id = ?', whereArgs: [squadId]);
  }

  @override
  Future<void> createSquad(String id, String name, String? templateId) async {
    final db = await appDatabase.database;
    await db.insert('base_squads', {
      'id': id,
      'name': name,
      'shift_template_id': templateId,
    });
  }

  @override
  Future<void> updateSquad(String id, String name, String? templateId) async {
    final db = await appDatabase.database;
    await db.update(
      'base_squads',
      {
        'name': name,
        'shift_template_id': templateId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteSquad(String id) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      // 1. Limpiar referencia en vecinos
      await txn.update(
        'neighbors',
        {'base_squad_id': null},
        where: 'base_squad_id = ?',
        whereArgs: [id],
      );
      // 2. Eliminar cuadrilla
      await txn.delete('base_squads', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> setNeighborSquad(String neighborId, String? squadId) async {
    final db = await appDatabase.database;
    await db.update(
      'neighbors',
      {'base_squad_id': squadId},
      where: 'id = ?',
      whereArgs: [neighborId],
    );
  }
}
