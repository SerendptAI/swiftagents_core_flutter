import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

void logDebug(dynamic message) {
  logger.d(message);
}

void logWarning(dynamic message) {
  logger.w(message);
}

void logInfo(String message) {
  logger.i(message);
}

void logError(
    Object error,
    StackTrace? trace,
    ) {
  logger.e('An Error Occurred', error: error, stackTrace: trace);

  if (error is DioException) {
    logger.e(error.response?.data);
  }
}


