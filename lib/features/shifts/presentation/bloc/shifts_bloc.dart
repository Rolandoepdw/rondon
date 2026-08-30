import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';

// Events
abstract class ShiftsEvent extends Equatable {
  const ShiftsEvent();
  @override
  List<Object> get props => [];
}

class LoadTodayShifts extends ShiftsEvent {}

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
class ShiftsError extends ShiftsState {
  final String message;
  const ShiftsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class ShiftsBloc extends Bloc<ShiftsEvent, ShiftsState> {
  final IShiftRepository repository;

  ShiftsBloc({required this.repository}) : super(ShiftsInitial()) {
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
  }
}
