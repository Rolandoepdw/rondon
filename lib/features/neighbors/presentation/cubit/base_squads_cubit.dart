import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';

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

class BaseSquadsCubit extends Cubit<BaseSquadsState> {
  final IBaseSquadRepository repository;

  BaseSquadsCubit({required this.repository}) : super(BaseSquadsInitial());

  Future<void> loadBaseSquads() async {
    emit(BaseSquadsLoading());
    final result = await repository.getAllSquads();
    result.fold(
      (failure) => emit(BaseSquadsError(failure.message)),
      (squads) => emit(BaseSquadsLoaded(squads)),
    );
  }

  Future<void> addBaseSquad(BaseSquadEntity squad) async {
    final result = await repository.createSquad(squad);
    result.fold(
      (failure) => emit(BaseSquadsError(failure.message)),
      (_) => loadBaseSquads(),
    );
  }

  Future<void> editBaseSquad(BaseSquadEntity squad) async {
    final result = await repository.updateSquad(squad);
    result.fold(
      (failure) => emit(BaseSquadsError(failure.message)),
      (_) => loadBaseSquads(),
    );
  }

  Future<void> removeBaseSquad(String id) async {
    final result = await repository.deleteSquad(id);
    result.fold(
      (failure) => emit(BaseSquadsError(failure.message)),
      (_) => loadBaseSquads(),
    );
  }
}
