import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Número de métodos de stack trace a imprimir
      errorMethodCount: 8, // Número de métodos de stack trace para errores
      lineLength: 120, // Longitud de línea
      colors: true, // Colores en consola
      printEmojis: true, // Emojis para diferentes niveles
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Incluir timestamp
    ),
  );

  // Métodos estáticos para diferentes niveles de log
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
