import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rondon/core/utils/app_bloc_observer.dart';
import 'package:rondon/injection_container.dart' as di;
import 'package:rondon/features/shifts/presentation/pages/home_page.dart';
import 'package:rondon/features/neighbors/presentation/pages/neighbors_page.dart';
import 'package:rondon/features/shifts/presentation/pages/calendar_page.dart';
import 'package:rondon/features/settings/presentation/pages/settings_page.dart';
import 'package:rondon/core/theme/app_theme.dart';
import 'package:rondon/core/services/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rondon/features/shifts/presentation/cubit/shifts_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/neighbors_cubit.dart';
import 'package:rondon/features/shifts/presentation/cubit/shift_templates_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/base_squads_cubit.dart';

void main() async {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  WidgetsFlutterBinding.ensureInitialized();
  
  dev.log('Starting app on platform: ${Platform.operatingSystem}', name: 'APP');

  await initializeDateFormatting('es_ES', null);
  Intl.defaultLocale = 'es_ES';
  
  await di.init();
  await di.sl<NotificationService>().init();

  Bloc.observer = AppBlocObserver();

  runApp(const RondonApp());
}

class RondonApp extends StatelessWidget {
  const RondonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<ShiftsCubit>()..loadTodayShifts()),
        BlocProvider(create: (_) => di.sl<NeighborsCubit>()..loadNeighbors()),
        BlocProvider(create: (_) => di.sl<ShiftTemplatesCubit>()),
        BlocProvider(create: (_) => di.sl<BaseSquadsCubit>()),
      ],
      child: MaterialApp(
        title: 'Rondon',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        theme: AppTheme.darkTheme,
        home: const MainNavigationPage(),
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomePage(),
          CalendarPage(),
          NeighborsPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Gestión',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
