import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/generate_cycle_schedule.dart';
import 'package:rondon/features/shifts/domain/usecases/audit_shift_attendance.dart';
import 'package:rondon/features/shifts/domain/usecases/execute_substitution.dart';
import 'package:rondon/features/shifts/domain/usecases/get_replacement_candidates.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';

// Events
abstract class ShiftsEvent extends Equatable {
  const ShiftsEvent();
  @override
  List<Object?> get props => [];
}

class LoadTodayShifts extends ShiftsEvent {}

class LoadShiftsRange extends ShiftsEvent {
  final DateTime start;
  final DateTime end;
  const LoadShiftsRange({required this.start, required this.end});
  @override
  List<Object> get props => [start, end];
}

class GenerateShiftsRange extends ShiftsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const GenerateShiftsRange({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

class AuditShift extends ShiftsEvent {
  final String shiftId;
  final Map<String, AttendanceStatus> attendanceMap;
  final String? notes;
  const AuditShift({required this.shiftId, required this.attendanceMap, this.notes});
  @override
  List<Object?> get props => [shiftId, attendanceMap, notes];
}

class PerformSubstitution extends ShiftsEvent {
  final String shiftId;
  final String originalNeighborId;
  final String? substituteNeighborId;
  final OperationalProfile effectiveProfile;

  const PerformSubstitution({
    required this.shiftId,
    required this.originalNeighborId,
    this.substituteNeighborId,
    required this.effectiveProfile,
  });

  @override
  List<Object?> get props => [shiftId, originalNeighborId, substituteNeighborId, effectiveProfile];
}

class LoadReplacementCandidates extends ShiftsEvent {
  final String shiftId;
  final String originalNeighborId;
  const LoadReplacementCandidates({required this.shiftId, required this.originalNeighborId});
  @override
  List<Object> get props => [shiftId, originalNeighborId];
}

// States
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

// Bloc
class ShiftsBloc extends Bloc<ShiftsEvent, ShiftsState> {
  final IShiftRepository repository;
  final GenerateCycleSchedule generateCycleSchedule;
  final AuditShiftAttendance auditShiftAttendance;
  final ExecuteSubstitution executeSubstitution;
  final GetReplacementCandidates getReplacementCandidates;

  ShiftsBloc({
    required this.repository,
    required this.generateCycleSchedule,
    required this.auditShiftAttendance,
    required this.executeSubstitution,
    required this.getReplacementCandidates,
  }) : super(ShiftsInitial()) {
    on<LoadTodayShifts>((event, emit) async {
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
    });

    on<LoadShiftsRange>((event, emit) async {
      emit(ShiftsLoading());
      final result = await repository.getShiftsByDateRange(event.start, event.end);
      result.fold(
        (failure) => emit(ShiftsError(failure.message)),
        (shifts) => emit(ShiftsLoaded(todayShifts: shifts, date: event.start)),
      );
    });

    on<GenerateShiftsRange>((event, emit) async {
      emit(ShiftsLoading());
      final result = await generateCycleSchedule(GenerateParams(
        startDate: event.startDate,
        endDate: event.endDate,
      ));

      result.fold(
        (failure) => emit(ShiftsError(failure.message)),
        (_) {
          emit(const ShiftsSuccess('Planificación generada con éxito'));
          add(LoadTodayShifts());
        },
      );
    });

    on<AuditShift>((event, emit) async {
      emit(ShiftsLoading());
      final result = await auditShiftAttendance(AuditParams(
        shiftId: event.shiftId,
        attendanceMap: event.attendanceMap,
        notes: event.notes,
      ));

      result.fold(
        (failure) => emit(ShiftsError(failure.message)),
        (_) {
          emit(const ShiftsSuccess('Asistencia auditada correctamente'));
          add(LoadTodayShifts());
        },
      );
    });

    on<LoadReplacementCandidates>((event, emit) async {
      emit(ShiftsLoading());
      final result = await getReplacementCandidates(ReplacementParams(
        shiftId: event.shiftId,
        originalNeighborId: event.originalNeighborId,
      ));

      result.fold(
        (failure) => emit(ShiftsError(failure.message)),
        (candidates) => emit(ReplacementCandidatesLoaded(candidates)),
      );
    });

    on<PerformSubstitution>((event, emit) async {
      emit(ShiftsLoading());
      final result = await executeSubstitution(SubstitutionParams(
        shiftId: event.shiftId,
        originalNeighborId: event.originalNeighborId,
        substituteNeighborId: event.substituteNeighborId,
        effectiveProfile: event.effectiveProfile,
      ));

      result.fold(
        (failure) => emit(ShiftsError(failure.message)),
        (_) {
          emit(const ShiftsSuccess('Sustitución realizada con éxito'));
          add(LoadTodayShifts());
        },
      );
    });
  }
}
