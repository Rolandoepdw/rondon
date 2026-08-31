import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/usecases/get_all_squads.dart';
import 'package:rondon/features/neighbors/domain/usecases/create_base_squad.dart';
import 'package:rondon/features/neighbors/domain/usecases/update_base_squad.dart';
import 'package:rondon/features/neighbors/domain/usecases/delete_base_squad.dart';

// Events
abstract class BaseSquadsEvent extends Equatable {
  const BaseSquadsEvent();
  @override
  List<Object> get props => [];
}

class LoadBaseSquads extends BaseSquadsEvent {}

class AddBaseSquad extends BaseSquadsEvent {
  final BaseSquadEntity squad;
  const AddBaseSquad(this.squad);
  @override
  List<Object> get props => [squad];
}

class EditBaseSquad extends BaseSquadsEvent {
  final BaseSquadEntity squad;
  const EditBaseSquad(this.squad);
  @override
  List<Object> get props => [squad];
}

class RemoveBaseSquad extends BaseSquadsEvent {
  final String id;
  const RemoveBaseSquad(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class BaseSquadsState extends Equatable {
  const BaseSquadsState();
  @override
  List<Object> get props => [];
}

class BaseSquadsInitial extends BaseSquadsState {}
class BaseSquadsLoading extends BaseSquadsState {}
class BaseSquadsLoaded extends BaseSquadsState {
  final List<BaseSquadEntity> squads;
  const BaseSquadsLoaded(this.squads);
  @override
  List<Object> get props => [squads];
}
class BaseSquadsError extends BaseSquadsState {
  final String message;
  const BaseSquadsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class BaseSquadsBloc extends Bloc<BaseSquadsEvent, BaseSquadsState> {
  final GetAllSquads getAllSquads;
  final CreateBaseSquad createBaseSquad;
  final UpdateBaseSquad updateBaseSquad;
  final DeleteBaseSquad deleteBaseSquad;

  BaseSquadsBloc({
    required this.getAllSquads,
    required this.createBaseSquad,
    required this.updateBaseSquad,
    required this.deleteBaseSquad,
  }) : super(BaseSquadsInitial()) {
    on<LoadBaseSquads>((event, emit) async {
      emit(BaseSquadsLoading());
      final result = await getAllSquads(NoParams());
      result.fold(
        (failure) => emit(BaseSquadsError(failure.message)),
        (squads) => emit(BaseSquadsLoaded(squads)),
      );
    });

    on<AddBaseSquad>((event, emit) async {
      final result = await createBaseSquad(event.squad);
      result.fold(
        (failure) => emit(BaseSquadsError(failure.message)),
        (_) => add(LoadBaseSquads()),
      );
    });

    on<EditBaseSquad>((event, emit) async {
      final result = await updateBaseSquad(event.squad);
      result.fold(
        (failure) => emit(BaseSquadsError(failure.message)),
        (_) => add(LoadBaseSquads()),
      );
    });

    on<RemoveBaseSquad>((event, emit) async {
      final result = await deleteBaseSquad(event.id);
      result.fold(
        (failure) => emit(BaseSquadsError(failure.message)),
        (_) => add(LoadBaseSquads()),
      );
    });
  }
}
