import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  final AppDatabase appDatabase;

  SettingsRepositoryImpl({required this.appDatabase});

  @override
  Future<Either<Failure, int>> getMinDaysBetweenShifts() async {
    try {
      final db = await appDatabase.database;
      final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['min_days_between_shifts']);
      if (result.isNotEmpty) {
        return Right(int.parse(result.first['value'] as String));
      }
      return const Right(3);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setMinDaysBetweenShifts(int days) async {
    try {
      final db = await appDatabase.database;
      await db.update('app_settings', {'value': days.toString()}, where: 'key = ?', whereArgs: ['min_days_between_shifts']);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getAllowUnderQuota() async {
    try {
      final db = await appDatabase.database;
      final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['allow_under_quota']);
      if (result.isNotEmpty) {
        return Right((result.first['value'] as String) == '1');
      }
      return const Right(true);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setAllowUnderQuota(bool allow) async {
    try {
      final db = await appDatabase.database;
      await db.update('app_settings', {'value': allow ? '1' : '0'}, where: 'key = ?', whereArgs: ['allow_under_quota']);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getMorningNotificationTime() async {
    try {
      final db = await appDatabase.database;
      final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['notification_time_morning']);
      if (result.isNotEmpty) return Right(result.first['value'] as String);
      return const Right('08:00');
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setMorningNotificationTime(String time) async {
    try {
      final db = await appDatabase.database;
      await db.update('app_settings', {'value': time}, where: 'key = ?', whereArgs: ['notification_time_morning']);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getEveningNotificationTime() async {
    try {
      final db = await appDatabase.database;
      final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['notification_time_evening']);
      if (result.isNotEmpty) return Right(result.first['value'] as String);
      return const Right('20:00');
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setEveningNotificationTime(String time) async {
    try {
      final db = await appDatabase.database;
      await db.update('app_settings', {'value': time}, where: 'key = ?', whereArgs: ['notification_time_evening']);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
