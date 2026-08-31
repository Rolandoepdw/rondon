import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/shifts/data/models/shift_template_model.dart';

abstract class ShiftTemplateLocalDataSource {
  Future<List<ShiftTemplateModel>> getActiveTemplates();
  Future<void> createTemplate(ShiftTemplateModel template);
  Future<void> updateTemplate(ShiftTemplateModel template);
  Future<void> deleteTemplate(String id);
}

class ShiftTemplateLocalDataSourceImpl implements ShiftTemplateLocalDataSource {
  final AppDatabase appDatabase;

  ShiftTemplateLocalDataSourceImpl({required this.appDatabase});

  @override
  Future<List<ShiftTemplateModel>> getActiveTemplates() async {
    final db = await appDatabase.database;
    final result = await db.query(
      'shift_templates',
      where: 'is_active = 1',
      orderBy: 'display_order ASC',
    );
    return result.map((map) => ShiftTemplateModel.fromMap(map)).toList();
  }

  @override
  Future<void> createTemplate(ShiftTemplateModel template) async {
    final db = await appDatabase.database;
    await db.insert('shift_templates', template.toMap());
  }

  @override
  Future<void> updateTemplate(ShiftTemplateModel template) async {
    final db = await appDatabase.database;
    await db.update(
      'shift_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  @override
  Future<void> deleteTemplate(String id) async {
    final db = await appDatabase.database;
    // En lugar de borrar físicamente, podemos marcar como inactivo para no romper histórico
    await db.update(
      'shift_templates',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
