import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    dev.log('CREATED: ${bloc.runtimeType}', name: 'BLOC');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    dev.log('CHANGE in ${bloc.runtimeType}: ${change.currentState} -> ${change.nextState}', name: 'BLOC');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    dev.log('ERROR in ${bloc.runtimeType}: $error', name: 'BLOC', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    dev.log('CLOSED: ${bloc.runtimeType}', name: 'BLOC');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    dev.log('EVENT in ${bloc.runtimeType}: $event', name: 'BLOC');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    dev.log('TRANSITION in ${bloc.runtimeType}: ${transition.event} -> ${transition.nextState}', name: 'BLOC');
  }
}
