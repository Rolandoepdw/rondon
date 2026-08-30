import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/usecases/get_all_neighbors.dart';
import 'package:rondon/features/neighbors/domain/usecases/create_neighbor.dart';
import 'package:rondon/features/neighbors/domain/usecases/update_neighbor.dart';
import 'package:rondon/features/neighbors/domain/usecases/delete_neighbor.dart';

// Events
abstract class NeighborsEvent extends Equatable {
  const NeighborsEvent();
  @override
  List<Object> get props => [];
}

class LoadNeighbors extends NeighborsEvent {}

class AddNeighbor extends NeighborsEvent {
  final NeighborEntity neighbor;
  const AddNeighbor(this.neighbor);
  @override
  List<Object> get props => [neighbor];
}

class EditNeighbor extends NeighborsEvent {
  final NeighborEntity neighbor;
  const EditNeighbor(this.neighbor);
  @override
  List<Object> get props => [neighbor];
}

class RemoveNeighbor extends NeighborsEvent {
  final String id;
  const RemoveNeighbor(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class NeighborsState extends Equatable {
  const NeighborsState();
  @override
  List<Object> get props => [];
}

class NeighborsInitial extends NeighborsState {}
class NeighborsLoading extends NeighborsState {}
class NeighborsLoaded extends NeighborsState {
  final List<NeighborEntity> neighbors;
  const NeighborsLoaded(this.neighbors);
  @override
  List<Object> get props => [neighbors];
}
class NeighborsError extends NeighborsState {
  final String message;
  const NeighborsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class NeighborsBloc extends Bloc<NeighborsEvent, NeighborsState> {
  final GetAllNeighbors getAllNeighbors;
  final CreateNeighbor createNeighbor;
  final UpdateNeighbor updateNeighbor;
  final DeleteNeighbor deleteNeighbor;

  NeighborsBloc({
    required this.getAllNeighbors,
    required this.createNeighbor,
    required this.updateNeighbor,
    required this.deleteNeighbor,
  }) : super(NeighborsInitial()) {
    on<LoadNeighbors>((event, emit) async {
      emit(NeighborsLoading());
      final result = await getAllNeighbors(true);
      result.fold(
        (failure) => emit(NeighborsError(failure.message)),
        (neighbors) => emit(NeighborsLoaded(neighbors)),
      );
    });

    on<AddNeighbor>((event, emit) async {
      final result = await createNeighbor(event.neighbor);
      result.fold(
        (failure) => emit(NeighborsError(failure.message)),
        (_) => add(LoadNeighbors()),
      );
    });

    on<EditNeighbor>((event, emit) async {
      final result = await updateNeighbor(event.neighbor);
      result.fold(
        (failure) => emit(NeighborsError(failure.message)),
        (_) => add(LoadNeighbors()),
      );
    });

    on<RemoveNeighbor>((event, emit) async {
      final result = await deleteNeighbor(event.id);
      result.fold(
        (failure) => emit(NeighborsError(failure.message)),
        (_) => add(LoadNeighbors()),
      );
    });
  }
}
