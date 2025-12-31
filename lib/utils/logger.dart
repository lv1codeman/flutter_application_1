import 'package:logger/logger.dart';

class Log {
  static final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void e(String message) => _logger.e(message);
}
