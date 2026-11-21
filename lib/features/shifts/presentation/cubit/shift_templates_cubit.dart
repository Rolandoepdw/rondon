import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';

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

class ShiftTemplatesCubit extends Cubit<ShiftTemplatesState> {
  final IShiftTemplateRepository repository;

  ShiftTemplatesCubit({required this.repository}) : super(ShiftTemplatesInitial());

  Future<void> loadShiftTemplates() async {
    emit(ShiftTemplatesLoading());
    final result = await repository.getActiveTemplates();
    result.fold(
      (failure) => emit(ShiftTemplatesError(failure.message)),
      (templates) => emit(ShiftTemplatesLoaded(templates)),
    );
  }

  Future<void> addShiftTemplate(ShiftTemplateEntity template) async {
    final result = await repository.createTemplate(template);
    result.fold(
      (failure) => emit(ShiftTemplatesError(failure.message)),
      (_) => loadShiftTemplates(),
    );
  }

  Future<void> editShiftTemplate(ShiftTemplateEntity template) async {
    final result = await repository.updateTemplate(template);
    result.fold(
      (failure) => emit(ShiftTemplatesError(failure.message)),
      (_) => loadShiftTemplates(),
    );
  }

  Future<void> removeShiftTemplate(String id) async {
    final result = await repository.deleteTemplate(id);
    result.fold(
      (failure) => emit(ShiftTemplatesError(failure.message)),
      (_) => loadShiftTemplates(),
    );
  }
}
