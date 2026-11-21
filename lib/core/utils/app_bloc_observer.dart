import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/utils/app_logger.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    AppLogger.cubit(bloc.runtimeType.toString(), 'INITIALIZED');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    
    // Detection of duplicate state emissions
    if (change.currentState == change.nextState) {
      AppLogger.duplicateState(
        bloc.runtimeType.toString(), 
        change.nextState.toString(),
      );
    } else {
      AppLogger.cubit(
        bloc.runtimeType.toString(), 
        'STATE CHANGE: ${change.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    AppLogger.error('CUBIT_ERROR', 'Error in ${bloc.runtimeType}', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    AppLogger.cubit(bloc.runtimeType.toString(), 'CLOSED');
  }
}
