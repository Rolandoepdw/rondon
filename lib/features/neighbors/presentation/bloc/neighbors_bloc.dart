import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/entities/balance_ledger_record.dart';
import 'package:rondon/features/neighbors/domain/usecases/get_all_neighbors.dart';
import 'package:rondon/features/neighbors/domain/usecases/create_neighbor.dart';
import 'package:rondon/features/neighbors/domain/usecases/update_neighbor.dart';
import 'package:rondon/features/neighbors/domain/usecases/delete_neighbor.dart';
import 'package:rondon/features/neighbors/domain/usecases/get_ledger_history.dart';

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

class LoadLedgerHistory extends NeighborsEvent {
  final String neighborId;
  const LoadLedgerHistory(this.neighborId);
  @override
  List<Object> get props => [neighborId];
}

// State
class NeighborsState extends Equatable {
  final List<NeighborEntity> neighbors;
  final List<BalanceLedgerRecordEntity> ledgerHistory;
  final bool isLoading;
  final String? errorMessage;

  const NeighborsState({
    this.neighbors = const [],
    this.ledgerHistory = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  NeighborsState copyWith({
    List<NeighborEntity>? neighbors,
    List<BalanceLedgerRecordEntity>? ledgerHistory,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NeighborsState(
      neighbors: neighbors ?? this.neighbors,
      ledgerHistory: ledgerHistory ?? this.ledgerHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [neighbors, ledgerHistory, isLoading, errorMessage];
}

// Bloc
class NeighborsBloc extends Bloc<NeighborsEvent, NeighborsState> {
  final GetAllNeighbors getAllNeighbors;
  final CreateNeighbor createNeighbor;
  final UpdateNeighbor updateNeighbor;
  final DeleteNeighbor deleteNeighbor;
  final GetLedgerHistory getLedgerHistory;

  NeighborsBloc({
    required this.getAllNeighbors,
    required this.createNeighbor,
    required this.updateNeighbor,
    required this.deleteNeighbor,
    required this.getLedgerHistory,
  }) : super(const NeighborsState()) {
    on<LoadNeighbors>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await getAllNeighbors(true);
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
        (neighbors) => emit(state.copyWith(isLoading: false, neighbors: neighbors)),
      );
    });

    on<AddNeighbor>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await createNeighbor(event.neighbor);
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
        (_) => add(LoadNeighbors()),
      );
    });

    on<EditNeighbor>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await updateNeighbor(event.neighbor);
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
        (_) => add(LoadNeighbors()),
      );
    });

    on<RemoveNeighbor>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await deleteNeighbor(event.id);
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
        (_) => add(LoadNeighbors()),
      );
    });

    on<LoadLedgerHistory>((event, emit) async {
      emit(state.copyWith(isLoading: true, ledgerHistory: []));
      final result = await getLedgerHistory(event.neighborId);
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
        (history) => emit(state.copyWith(isLoading: false, ledgerHistory: history)),
      );
    });
  }
}
