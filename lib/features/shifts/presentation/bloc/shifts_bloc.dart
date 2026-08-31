import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/generate_cycle_schedule.dart';

// Events
abstract class ShiftsEvent extends Equatable {
  const ShiftsEvent();
  @override
  List<Object> get props => [];
}

class LoadTodayShifts extends ShiftsEvent {}

class GenerateShiftsRange extends ShiftsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const GenerateShiftsRange({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

class LoadShiftsRange extends ShiftsEvent {
  final DateTime start;
  final DateTime end;
  const LoadShiftsRange({required this.start, required this.end});
  @override
  List<Object> get props => [start, end];
}

// States
abstract class ShiftsState extends Equatable {
  const ShiftsState();
  @override
  List<Object> get props => [];
}

class ShiftsInitial extends ShiftsState {}
class ShiftsLoading extends ShiftsState {}
class ShiftsLoaded extends ShiftsState {
  final List<ScheduledShiftEntity> shifts;
  final DateTime date;
  const ShiftsLoaded(this.shifts, this.date);
  @override
  List<Object> get props => [shifts, date];
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

// Bloc
class ShiftsBloc extends Bloc<ShiftsEvent, ShiftsState> {
  final IShiftRepository repository;
  final GenerateCycleSchedule generateCycleSchedule;

  ShiftsBloc({
    required this.repository,
    required this.generateCycleSchedule,
  }) : super(ShiftsInitial()) {
    on<LoadTodayShifts>((event, emit) async {
      emit(ShiftsLoading());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final result = await repository.getShiftsByDateRange(today, today);
      
      result.fold(
        (failure) => emit(ShiftsError(failure.message)),
        (shifts) => emit(ShiftsLoaded(shifts, today)),
      );
    });

    on<LoadShiftsRange>((event, emit) async {
      emit(ShiftsLoading());
      final result = await repository.getShiftsByDateRange(event.start, event.end);
      result.fold(
        (failure) => emit(ShiftsError(failure.message)),
        (shifts) => emit(ShiftsLoaded(shifts, event.start)),
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
  }
}
