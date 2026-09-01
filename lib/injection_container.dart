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

import 'package:rondon/features/shifts/data/datasources/shift_template_local_datasource.dart';
import 'package:rondon/features/shifts/data/repositories/shift_template_repository_impl.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';
import 'package:rondon/features/shifts/domain/usecases/get_active_templates.dart';
import 'package:rondon/features/shifts/domain/usecases/create_shift_template.dart';
import 'package:rondon/features/shifts/domain/usecases/update_shift_template.dart';
import 'package:rondon/features/shifts/domain/usecases/delete_shift_template.dart';
import 'package:rondon/features/shifts/presentation/bloc/shift_templates_bloc.dart';

import 'package:rondon/features/neighbors/data/datasources/base_squad_local_datasource.dart';
import 'package:rondon/features/neighbors/data/repositories/base_squad_repository_impl.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';
import 'package:rondon/features/neighbors/domain/usecases/get_all_squads.dart';
import 'package:rondon/features/neighbors/domain/usecases/create_base_squad.dart';
import 'package:rondon/features/neighbors/domain/usecases/update_base_squad.dart';
import 'package:rondon/features/neighbors/domain/usecases/delete_base_squad.dart';
import 'package:rondon/features/neighbors/presentation/bloc/base_squads_bloc.dart';

import 'package:rondon/features/shifts/domain/usecases/generate_cycle_schedule.dart';
import 'package:rondon/features/shifts/domain/usecases/audit_shift_attendance.dart';
import 'package:rondon/features/shifts/domain/usecases/execute_substitution.dart';

import 'package:rondon/features/messaging/domain/usecases/build_reminder_message.dart';
import 'package:rondon/core/services/whatsapp_service.dart';
import 'package:rondon/core/services/notification_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Messaging
  sl.registerLazySingleton(() => BuildReminderMessage());
  sl.registerLazySingleton(() => WhatsAppService());
  sl.registerLazySingleton(() => NotificationService());

  //! Presentation
  sl.registerFactory(() => ShiftsBloc(
        repository: sl(),
        generateCycleSchedule: sl(),
        auditShiftAttendance: sl(),
        executeSubstitution: sl(),
        getReplacementCandidates: sl(),
      ));
  sl.registerFactory(() => NeighborsBloc(
        getAllNeighbors: sl(),
        createNeighbor: sl(),
        updateNeighbor: sl(),
        deleteNeighbor: sl(),
      ));
  sl.registerFactory(() => ShiftTemplatesBloc(
        getActiveTemplates: sl(),
        createShiftTemplate: sl(),
        updateShiftTemplate: sl(),
        deleteShiftTemplate: sl(),
      ));
  sl.registerFactory(() => BaseSquadsBloc(
        getAllSquads: sl(),
        createBaseSquad: sl(),
        updateBaseSquad: sl(),
        deleteBaseSquad: sl(),
      ));

  //! Features - Neighbors
  // Usecases
  sl.registerLazySingleton(() => GetAllNeighbors(sl()));
  sl.registerLazySingleton(() => CreateNeighbor(sl()));
  sl.registerLazySingleton(() => UpdateNeighbor(sl()));
  sl.registerLazySingleton(() => DeleteNeighbor(sl()));
  sl.registerLazySingleton(() => UpdateBalance(sl()));
  sl.registerLazySingleton(() => GetAllSquads(sl()));
  sl.registerLazySingleton(() => CreateBaseSquad(sl()));
  sl.registerLazySingleton(() => UpdateBaseSquad(sl()));
  sl.registerLazySingleton(() => DeleteBaseSquad(sl()));

  // Repository
  sl.registerLazySingleton<INeighborRepository>(
    () => NeighborRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<IBaseSquadRepository>(
    () => BaseSquadRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<NeighborLocalDataSource>(
    () => NeighborLocalDataSourceImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<BaseSquadLocalDataSource>(
    () => BaseSquadLocalDataSourceImpl(appDatabase: sl()),
  );

  //! Features - Shifts
  // Usecases
  sl.registerLazySingleton(() => GetReplacementCandidates(
        neighborRepository: sl(),
        shiftRepository: sl(),
        settingsRepository: sl(),
      ));
  sl.registerLazySingleton(() => GetActiveTemplates(sl()));
  sl.registerLazySingleton(() => CreateShiftTemplate(sl()));
  sl.registerLazySingleton(() => UpdateShiftTemplate(sl()));
  sl.registerLazySingleton(() => DeleteShiftTemplate(sl()));
  sl.registerLazySingleton(() => GenerateCycleSchedule(
        neighborRepository: sl(),
        squadRepository: sl(),
        templateRepository: sl(),
        shiftRepository: sl(),
        settingsRepository: sl(),
      ));
  sl.registerLazySingleton(() => AuditShiftAttendance(sl()));
  sl.registerLazySingleton(() => ExecuteSubstitution(sl()));

  // Repository
  sl.registerLazySingleton<IShiftRepository>(
    () => ShiftRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<IShiftTemplateRepository>(
    () => ShiftTemplateRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ShiftLocalDataSource>(
    () => ShiftLocalDataSourceImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<ShiftTemplateLocalDataSource>(
    () => ShiftTemplateLocalDataSourceImpl(appDatabase: sl()),
  );

  //! Features - Settings
  sl.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepositoryImpl(appDatabase: sl()),
  );

  //! External
  sl.registerLazySingleton(() => AppDatabase.instance);
}
