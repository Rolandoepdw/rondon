import 'package:get_it/get_it.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/neighbors/data/repositories/neighbor_repository_impl.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';
import 'package:rondon/features/neighbors/data/repositories/base_squad_repository_impl.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';

import 'package:rondon/features/shifts/data/repositories/shift_repository_impl.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/shifts/data/repositories/shift_template_repository_impl.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';

import 'package:rondon/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';

import 'package:rondon/features/shifts/presentation/cubit/shifts_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/neighbors_cubit.dart';
import 'package:rondon/features/shifts/presentation/cubit/shift_templates_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/base_squads_cubit.dart';

import 'package:rondon/features/shifts/domain/usecases/get_replacement_candidates.dart';
import 'package:rondon/features/shifts/domain/usecases/generate_cycle_schedule.dart';
import 'package:rondon/features/shifts/domain/usecases/audit_shift_attendance.dart';
import 'package:rondon/features/shifts/domain/usecases/execute_substitution.dart';

import 'package:rondon/features/messaging/domain/usecases/build_reminder_message.dart';
import 'package:rondon/core/services/whatsapp_service.dart';
import 'package:rondon/core/services/notification_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Messaging & Services
  sl.registerLazySingleton(() => BuildReminderMessage());
  sl.registerLazySingleton(() => WhatsAppService());
  sl.registerLazySingleton(() => NotificationService());

  //! Presentation / Cubits
  sl.registerFactory(() => ShiftsCubit(
        repository: sl(),
        generateCycleSchedule: sl(),
        auditShiftAttendance: sl(),
        executeSubstitution: sl(),
        getReplacementCandidates: sl(),
      ));
  sl.registerFactory(() => NeighborsCubit(repository: sl()));
  sl.registerFactory(() => ShiftTemplatesCubit(repository: sl()));
  sl.registerFactory(() => BaseSquadsCubit(repository: sl()));

  //! Repositories
  sl.registerLazySingleton<INeighborRepository>(
    () => NeighborRepositoryImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<IBaseSquadRepository>(
    () => BaseSquadRepositoryImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<IShiftRepository>(
    () => ShiftRepositoryImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<IShiftTemplateRepository>(
    () => ShiftTemplateRepositoryImpl(appDatabase: sl()),
  );
  sl.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepositoryImpl(appDatabase: sl()),
  );

  //! Complex Use Cases
  sl.registerLazySingleton(() => GetReplacementCandidates(
        neighborRepository: sl(),
        shiftRepository: sl(),
        settingsRepository: sl(),
      ));
  sl.registerLazySingleton(() => GenerateCycleSchedule(
        neighborRepository: sl(),
        squadRepository: sl(),
        templateRepository: sl(),
        shiftRepository: sl(),
        settingsRepository: sl(),
      ));
  sl.registerLazySingleton(() => AuditShiftAttendance(sl()));
  sl.registerLazySingleton(() => ExecuteSubstitution(sl()));

  //! External / Database
  sl.registerLazySingleton(() => AppDatabase.instance);
}
