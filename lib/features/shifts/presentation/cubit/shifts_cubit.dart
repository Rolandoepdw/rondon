import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/generate_cycle_schedule.dart';
import 'package:rondon/features/shifts/domain/usecases/audit_shift_attendance.dart';
import 'package:rondon/features/shifts/domain/usecases/execute_substitution.dart';
import 'package:rondon/features/shifts/domain/usecases/get_replacement_candidates.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';

abstract class ShiftsState extends Equatable {
  const ShiftsState();
  @override
  List<Object?> get props => [];
}

class ShiftsInitial extends ShiftsState {}
class ShiftsLoading extends ShiftsState {}
class ShiftsLoaded extends ShiftsState {
  final List<ScheduledShiftEntity> todayShifts;
  final List<ScheduledShiftEntity> pendingAuditShifts;
  final DateTime date;
  const ShiftsLoaded({
    required this.todayShifts,
    this.pendingAuditShifts = const [],
    required this.date,
  });
  @override
  List<Object> get props => [todayShifts, pendingAuditShifts, date];

  @override
  String toString() {
    return 'ShiftsLoaded(today: ${todayShifts.length}, pending: ${pendingAuditShifts.length}, date: $date)';
  }
}
class ShiftsSuccess extends ShiftsState {
  final String message;
  const ShiftsSuccess(this.message);
  @override
  List<Object> get props => [message];
}
class ShiftsError extends ShiftsState {
  final String message;
  const ShiftsError(this.message);
  @override
  List<Object> get props => [message];
}

class ReplacementCandidatesLoaded extends ShiftsState {
  final List<NeighborCandidate> candidates;
  const ReplacementCandidatesLoaded(this.candidates);
  @override
  List<Object> get props => [candidates];
}

class ShiftsCubit extends Cubit<ShiftsState> {
  final IShiftRepository repository;
  final GenerateCycleSchedule generateCycleSchedule;
  final AuditShiftAttendance auditShiftAttendance;
  final ExecuteSubstitution executeSubstitution;
  final GetReplacementCandidates getReplacementCandidates;

  ShiftsCubit({
    required this.repository,
    required this.generateCycleSchedule,
    required this.auditShiftAttendance,
    required this.executeSubstitution,
    required this.getReplacementCandidates,
  }) : super(ShiftsInitial());

  Future<void> loadTodayShifts() async {
    emit(ShiftsLoading());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final farPast = DateTime(2000);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final todayResult = await repository.getShiftsByDateRange(today, today);
    final pastResult = await repository.getShiftsByDateRange(farPast, yesterday);
    
    todayResult.fold(
      (failure) => emit(ShiftsError(failure.message)),
      (todayShifts) {
        pastResult.fold(
          (_) => emit(ShiftsLoaded(todayShifts: todayShifts, date: today)),
          (allPastShifts) {
            final pending = allPastShifts.where((s) => s.status != ShiftStatus.auditado).toList();
            emit(ShiftsLoaded(
              todayShifts: todayShifts,
              pendingAuditShifts: pending,
              date: today,
            ));
          },
        );
      },
    );
  }

  Future<void> loadShiftsRange(DateTime start, DateTime end) async {
    emit(ShiftsLoading());
    final result = await repository.getShiftsByDateRange(start, end);
    result.fold(
      (failure) => emit(ShiftsError(failure.message)),
      (shifts) => emit(ShiftsLoaded(todayShifts: shifts, date: start)),
    );
  }

  Future<void> generateShiftsRange(DateTime startDate, DateTime endDate) async {
    emit(ShiftsLoading());
    final result = await generateCycleSchedule(GenerateParams(
      startDate: startDate,
      endDate: endDate,
    ));

    result.fold(
      (failure) => emit(ShiftsError(failure.message)),
      (_) {
        emit(const ShiftsSuccess('Planificación generada con éxito'));
        loadTodayShifts();
      },
    );
  }

  Future<void> auditShift({required String shiftId, required Map<String, AttendanceStatus> attendanceMap, String? notes}) async {
    emit(ShiftsLoading());
    final result = await auditShiftAttendance(AuditParams(
      shiftId: shiftId,
      attendanceMap: attendanceMap,
      notes: notes,
    ));

    result.fold(
      (failure) => emit(ShiftsError(failure.message)),
      (_) {
        emit(const ShiftsSuccess('Asistencia auditada correctamente'));
        loadTodayShifts();
      },
    );
  }

  Future<void> loadReplacementCandidates({required String shiftId, required String originalNeighborId}) async {
    emit(ShiftsLoading());
    final result = await getReplacementCandidates(ReplacementParams(
      shiftId: shiftId,
      originalNeighborId: originalNeighborId,
    ));

    result.fold(
      (failure) => emit(ShiftsError(failure.message)),
      (candidates) => emit(ReplacementCandidatesLoaded(candidates)),
    );
  }

  Future<void> performSubstitution({
    required String shiftId,
    required String originalNeighborId,
    String? substituteNeighborId,
    required OperationalProfile effectiveProfile,
  }) async {
    emit(ShiftsLoading());
    final result = await executeSubstitution(SubstitutionParams(
      shiftId: shiftId,
      originalNeighborId: originalNeighborId,
      substituteNeighborId: substituteNeighborId,
      effectiveProfile: effectiveProfile,
    ));

    result.fold(
      (failure) => emit(ShiftsError(failure.message)),
      (_) {
        emit(const ShiftsSuccess('Sustitución realizada con éxito'));
        loadTodayShifts();
      },
    );
  }
}
