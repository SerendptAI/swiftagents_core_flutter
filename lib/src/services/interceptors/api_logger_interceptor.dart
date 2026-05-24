// ignore_for_file: strict_raw_type
import 'package:dio/dio.dart';
import '../../utils/logger.dart';

class ApiLoggerInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {
    logDebug({
      'type': 'Request--->',
      'url': options.uri.toString(),
      'method': options.method,
      'payload': options.data,
    });
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logDebug({
      'type': 'Response<---',
      'url': response.realUri.toString(),
      'response': response.data,
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logWarning({
      'type': 'Response<---!!!!!!!!!!!',
      'url': err.response?.realUri.toString(),
      'status': err.response?.statusCode,
      'response': err.response?.data,
    });
    handler.next(err); // Continue error flow
  }
}