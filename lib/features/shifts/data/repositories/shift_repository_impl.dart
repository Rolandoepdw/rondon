import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/data/datasources/shift_local_datasource.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/data/models/scheduled_shift_model.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';

class ShiftRepositoryImpl implements IShiftRepository {
  final ShiftLocalDataSource localDataSource;

  ShiftRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<ScheduledShiftEntity>>> getShiftsByDateRange(DateTime start, DateTime end) async {
    try {
      final shifts = await localDataSource.getShiftsByDateRange(start, end);
      return Right(shifts);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduledShiftEntity?>> getShiftById(String id) async {
    try {
      final shift = await localDataSource.getShiftById(id);
      return Right(shift);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveGeneratedShifts(List<ScheduledShiftEntity> shifts) async {
    try {
      final models = shifts.map((s) => ScheduledShiftModel(
        id: s.id,
        date: s.date,
        shiftTemplateId: s.shiftTemplateId,
        status: s.status,
        notes: s.notes,
        assignments: s.assignments,
      )).toList();
      await localDataSource.saveGeneratedShifts(models);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> executeSubstitution({
    required String shiftId,
    required String originalNeighborId,
    required String? substituteNeighborId,
    required OperationalProfile effectiveProfile,
  }) async {
    try {
      await localDataSource.executeSubstitution(
        shiftId: shiftId,
        originalNeighborId: originalNeighborId,
        substituteNeighborId: substituteNeighborId,
        effectiveProfile: effectiveProfile,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> auditShiftAttendance({
    required String shiftId,
    required Map<String, AttendanceStatus> attendanceMap,
    String? notes,
  }) async {
    try {
      await localDataSource.auditShiftAttendance(
        shiftId: shiftId,
        attendanceMap: attendanceMap,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastCompletedShiftDate(String neighborId, DateTime beforeDate) async {
    try {
      final date = await localDataSource.getLastCompletedShiftDate(neighborId, beforeDate);
      return Right(date);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
