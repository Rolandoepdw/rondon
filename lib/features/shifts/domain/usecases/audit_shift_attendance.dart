import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';

class AuditShiftAttendance implements UseCase<void, AuditParams> {
  final IShiftRepository repository;

  AuditShiftAttendance(this.repository);

  @override
  Future<Either<Failure, void>> call(AuditParams params) async {
    return await repository.auditShiftAttendance(
      shiftId: params.shiftId,
      attendanceMap: params.attendanceMap,
    );
  }
}

class AuditParams extends Equatable {
  final String shiftId;
  final Map<String, AttendanceStatus> attendanceMap;

  const AuditParams({required this.shiftId, required this.attendanceMap});

  @override
  List<Object?> get props => [shiftId, attendanceMap];
}
