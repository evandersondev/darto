import 'package:intl/intl.dart';

class Logger {
  // Códigos ANSI para cores
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _reset = '\x1B[0m';
  static const String _white = '\x1B[37m';
  static const String _gray = '\x1B[90m';

  final _formatter = DateFormat('HH:mm:ss.SSS');

  void info(String message) {
    print(
        '$_white[${_formatter.format(DateTime.now())}]$_green (INFO): $_gray$message$_reset');
  }

  void warn(String message) {
    print(
        '$_white[${_formatter.format(DateTime.now())}]$_yellow (WARN): $_gray$message$_reset');
  }

  void error(String message) {
    print(
        '$_white[${_formatter.format(DateTime.now())}]$_red (ERROR): $_gray$message$_reset');
  }

  void debug(String message) {
    print(
        '$_white[${_formatter.format(DateTime.now())}]$_blue (DEBUG): $_gray$message$_reset');
  }

  void access(String message) {
    print(
        '$_white[${_formatter.format(DateTime.now())}]$_magenta (ACCESS): $_gray$message$_reset');
  }
}
