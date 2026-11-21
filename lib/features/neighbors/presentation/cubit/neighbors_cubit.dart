import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/entities/balance_ledger_record.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

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

  @override
  String toString() {
    return 'NeighborsState(count: ${neighbors.length}, historyCount: ${ledgerHistory.length}, isLoading: $isLoading, error: $errorMessage)';
  }
}

class NeighborsCubit extends Cubit<NeighborsState> {
  final INeighborRepository repository;

  NeighborsCubit({required this.repository}) : super(const NeighborsState());

  Future<void> loadNeighbors() async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.getAllNeighbors(onlyActive: true);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (neighbors) => emit(state.copyWith(isLoading: false, neighbors: neighbors)),
    );
  }

  Future<void> addNeighbor(NeighborEntity neighbor) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.createNeighbor(neighbor);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) => loadNeighbors(),
    );
  }

  Future<void> editNeighbor(NeighborEntity neighbor) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.updateNeighbor(neighbor);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) => loadNeighbors(),
    );
  }

  Future<void> removeNeighbor(String id) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.deleteNeighbor(id);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) => loadNeighbors(),
    );
  }

  Future<void> loadLedgerHistory(String neighborId) async {
    emit(state.copyWith(isLoading: true, ledgerHistory: []));
    final result = await repository.getLedgerHistory(neighborId);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (history) => emit(state.copyWith(isLoading: false, ledgerHistory: history)),
    );
  }
}
