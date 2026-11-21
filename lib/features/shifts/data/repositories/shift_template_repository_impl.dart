import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/utils/app_logger.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';

class ShiftTemplateRepositoryImpl implements IShiftTemplateRepository {
  final AppDatabase appDatabase;

  ShiftTemplateRepositoryImpl({required this.appDatabase});

  @override
  Future<Either<Failure, List<ShiftTemplateEntity>>> getActiveTemplates() async {
    try {
      final db = await appDatabase.database;
      AppLogger.read('TEMPLATES', 'Fetching active shift templates');
      final result = await db.query(
        'shift_templates',
        where: 'is_active = 1',
        orderBy: 'display_order ASC',
      );
      final templates = result.map((map) => ShiftTemplateEntity.fromMap(map)).toList();
      return Right(templates);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createTemplate(ShiftTemplateEntity template) async {
    try {
      final db = await appDatabase.database;
      AppLogger.create('TEMPLATES', 'Creating template: ${template.name}');
      await db.insert('shift_templates', template.toMap());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTemplate(ShiftTemplateEntity template) async {
    try {
      final db = await appDatabase.database;
      AppLogger.update('TEMPLATES', 'Updating template ID: ${template.id}');
      await db.update(
        'shift_templates',
        template.toMap(),
        where: 'id = ?',
        whereArgs: [template.id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTemplate(String id) async {
    try {
      final db = await appDatabase.database;
      AppLogger.delete('TEMPLATES', 'Marking template ID: $id as inactive');
      await db.update(
        'shift_templates',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
