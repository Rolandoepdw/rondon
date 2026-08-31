import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/usecases/get_active_templates.dart';
import 'package:rondon/features/shifts/domain/usecases/create_shift_template.dart';
import 'package:rondon/features/shifts/domain/usecases/update_shift_template.dart';
import 'package:rondon/features/shifts/domain/usecases/delete_shift_template.dart';

// Events
abstract class ShiftTemplatesEvent extends Equatable {
  const ShiftTemplatesEvent();
  @override
  List<Object> get props => [];
}

class LoadShiftTemplates extends ShiftTemplatesEvent {}

class AddShiftTemplate extends ShiftTemplatesEvent {
  final ShiftTemplateEntity template;
  const AddShiftTemplate(this.template);
  @override
  List<Object> get props => [template];
}

class EditShiftTemplate extends ShiftTemplatesEvent {
  final ShiftTemplateEntity template;
  const EditShiftTemplate(this.template);
  @override
  List<Object> get props => [template];
}

class RemoveShiftTemplate extends ShiftTemplatesEvent {
  final String id;
  const RemoveShiftTemplate(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class ShiftTemplatesState extends Equatable {
  const ShiftTemplatesState();
  @override
  List<Object> get props => [];
}

class ShiftTemplatesInitial extends ShiftTemplatesState {}
class ShiftTemplatesLoading extends ShiftTemplatesState {}
class ShiftTemplatesLoaded extends ShiftTemplatesState {
  final List<ShiftTemplateEntity> templates;
  const ShiftTemplatesLoaded(this.templates);
  @override
  List<Object> get props => [templates];
}
class ShiftTemplatesError extends ShiftTemplatesState {
  final String message;
  const ShiftTemplatesError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class ShiftTemplatesBloc extends Bloc<ShiftTemplatesEvent, ShiftTemplatesState> {
  final GetActiveTemplates getActiveTemplates;
  final CreateShiftTemplate createShiftTemplate;
  final UpdateShiftTemplate updateShiftTemplate;
  final DeleteShiftTemplate deleteShiftTemplate;

  ShiftTemplatesBloc({
    required this.getActiveTemplates,
    required this.createShiftTemplate,
    required this.updateShiftTemplate,
    required this.deleteShiftTemplate,
  }) : super(ShiftTemplatesInitial()) {
    on<LoadShiftTemplates>((event, emit) async {
      emit(ShiftTemplatesLoading());
      final result = await getActiveTemplates(NoParams());
      result.fold(
        (failure) => emit(ShiftTemplatesError(failure.message)),
        (templates) => emit(ShiftTemplatesLoaded(templates)),
      );
    });

    on<AddShiftTemplate>((event, emit) async {
      final result = await createShiftTemplate(event.template);
      result.fold(
        (failure) => emit(ShiftTemplatesError(failure.message)),
        (_) => add(LoadShiftTemplates()),
      );
    });

    on<EditShiftTemplate>((event, emit) async {
      final result = await updateShiftTemplate(event.template);
      result.fold(
        (failure) => emit(ShiftTemplatesError(failure.message)),
        (_) => add(LoadShiftTemplates()),
      );
    });

    on<RemoveShiftTemplate>((event, emit) async {
      final result = await deleteShiftTemplate(event.id);
      result.fold(
        (failure) => emit(ShiftTemplatesError(failure.message)),
        (_) => add(LoadShiftTemplates()),
      );
    });
  }
}
