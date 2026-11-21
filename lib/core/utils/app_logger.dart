import 'dart:developer' as dev;

class AppLogger {
  static const bool _useAnsiColors = true;

  // ANSI Color Escape Codes
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _magenta = '\x1B[35m';
  static const _cyan = '\x1B[36m';
  static const _orange = '\x1B[38;5;208m';

  static void create(String tag, String message) {
    _log('🟩 [CREATE]', message, _green, tag);
  }

  static void read(String tag, String message) {
    _log('🟦 [READ]', message, _blue, tag);
  }

  static void update(String tag, String message) {
    _log('🟨 [UPDATE]', message, _yellow, tag);
  }

  static void delete(String tag, String message) {
    _log('🟥 [DELETE]', message, _red, tag);
  }

  static void cubit(String cubitName, String message) {
    _log('⚡ [CUBIT]', '$cubitName -> $message', _magenta, 'CUBIT');
  }

  static void duplicateState(String cubitName, String stateDetails) {
    _log('⚠️ [DUPLICATE_EMISSION]', 'REDUNDANT STATE EMITTED in $cubitName: $stateDetails', _orange, 'CUBIT_WARN');
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log('❌ [ERROR]', message, _red, tag);
    if (error != null) {
      dev.log('$_red$error$_reset', name: tag, error: error, stackTrace: stackTrace);
    }
  }

  static void info(String tag, String message) {
    _log('ℹ️ [INFO]', message, _cyan, tag);
  }

  static void _log(String prefix, String message, String color, String tag) {
    final formatted = _useAnsiColors ? '$color$prefix $message$_reset' : '$prefix $message';
    dev.log(formatted, name: tag);
  }
}
