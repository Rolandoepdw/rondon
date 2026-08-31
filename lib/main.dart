import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rondon/core/utils/app_bloc_observer.dart';
import 'package:rondon/injection_container.dart' as di;
import 'package:rondon/features/shifts/presentation/pages/home_page.dart';
import 'package:rondon/features/neighbors/presentation/pages/neighbors_page.dart';
import 'package:rondon/features/shifts/presentation/pages/calendar_page.dart';
import 'package:rondon/features/settings/presentation/pages/settings_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';
import 'package:rondon/features/neighbors/presentation/bloc/neighbors_bloc.dart';
import 'package:rondon/features/shifts/presentation/bloc/shift_templates_bloc.dart';
import 'package:rondon/features/neighbors/presentation/bloc/base_squads_bloc.dart';

void main() async {
  // 1. Inicializar sqflite_ffi si estamos en desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  WidgetsFlutterBinding.ensureInitialized();
  
  dev.log('Starting app on platform: ${Platform.operatingSystem}', name: 'APP');

  await initializeDateFormatting('es_ES', null);
  await di.init();

  Bloc.observer = AppBlocObserver();

  runApp(const RondonApp());
}

class RondonApp extends StatelessWidget {
  const RondonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<ShiftsBloc>()..add(LoadTodayShifts())),
        BlocProvider(create: (_) => di.sl<NeighborsBloc>()..add(LoadNeighbors())),
        BlocProvider(create: (_) => di.sl<ShiftTemplatesBloc>()),
        BlocProvider(create: (_) => di.sl<BaseSquadsBloc>()),
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
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
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Comunidad',
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
