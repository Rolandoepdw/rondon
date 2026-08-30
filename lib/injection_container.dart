import 'package:get_it/get_it.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/neighbors/data/datasources/neighbor_local_datasource.dart';
import 'package:rondon/features/neighbors/data/repositories/neighbor_repository_impl.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';
import 'package:rondon/features/neighbors/domain/usecases/create_neighbor.dart';
import 'package:rondon/features/neighbors/domain/usecases/get_all_neighbors.dart';
import 'package:rondon/features/neighbors/domain/usecases/update_balance.dart';
import 'package:rondon/features/shifts/data/datasources/shift_local_datasource.dart';
import 'package:rondon/features/shifts/data/repositories/shift_repository_impl.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/get_replacement_candidates.dart';
import 'package:rondon/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';
import 'package:rondon/features/neighbors/presentation/bloc/neighbors_bloc.dart';

import 'package:rondon/features/neighbors/domain/usecases/update_neighbor.dart';
import 'package:rondon/features/neighbors/domain/usecases/delete_neighbor.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Neighbors
  // Presentation
  sl.registerFactory(() => NeighborsBloc(
        getAllNeighbors: sl(),
        createNeighbor: sl(),
        updateNeighbor: sl(),
        deleteNeighbor: sl(),
      ));
  
  // Usecases
  sl.registerLazySingleton(() => GetAllNeighbors(sl()));
  sl.registerLazySingleton(() => CreateNeighbor(sl()));
  sl.registerLazySingleton(() => UpdateNeighbor(sl()));
  sl.registerLazySingleton(() => DeleteNeighbor(sl()));
  sl.registerLazySingleton(() => UpdateBalance(sl()));

  // Repository
  sl.registerLazySingleton<INeighborRepository>(
    () => NeighborRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<NeighborLocalDataSource>(
    () => NeighborLocalDataSourceImpl(appDatabase: sl()),
  );

  //! Features - Shifts
  // Presentation
  sl.registerFactory(() => ShiftsBloc(repository: sl()));

  // Usecases
  sl.registerLazySingleton(() => GetReplacementCandidates(
        neighborRepository: sl(),
        shiftRepository: sl(),
        settingsRepository: sl(),
      ));

  // Repository
  sl.registerLazySingleton<IShiftRepository>(
    () => ShiftRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ShiftLocalDataSource>(
    () => ShiftLocalDataSourceImpl(appDatabase: sl()),
  );

  //! Features - Settings
  sl.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepositoryImpl(appDatabase: sl()),
  );

  //! External
  sl.registerLazySingleton(() => AppDatabase.instance);
}
