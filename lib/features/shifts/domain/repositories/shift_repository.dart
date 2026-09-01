import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';

abstract class IShiftRepository {
  Future<Either<Failure, List<ScheduledShiftEntity>>> getShiftsByDateRange(DateTime start, DateTime end);
  Future<Either<Failure, ScheduledShiftEntity?>> getShiftById(String id);
  Future<Either<Failure, void>> saveGeneratedShifts(List<ScheduledShiftEntity> shifts);
  
  Future<Either<Failure, void>> executeSubstitution({
    required String shiftId,
    required String originalNeighborId,
    required String? substituteNeighborId,
    required OperationalProfile effectiveProfile,
  });

  Future<Either<Failure, void>> auditShiftAttendance({
    required String shiftId,
    required Map<String, AttendanceStatus> attendanceMap,
    String? notes,
  });

  Future<Either<Failure, DateTime?>> getLastCompletedShiftDate(String neighborId, DateTime beforeDate);
}
