import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:swift_agents_core/src/controllers/sdk_provider.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SdkProvider sdkProvider;

  AuthInterceptor(this.dio, {required this.sdkProvider});

  // 1. BEFORE SENDING THE REQUEST
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String? token = _getSavedAccessToken();

    if (token != null) {
      // Proactive Check: Use jwt_decoder to check expiration
      bool isExpired = false;
      try {
        isExpired = JwtDecoder.isExpired(token);
      } catch (e) {
        isExpired = true; // Treat malformed tokens as expired
      }

      if (isExpired) {
        // Token is expired! Refresh it before the request leaves the app
        final bool refreshSuccess = await _handleTokenRefresh();
        if (refreshSuccess) {
          token = _getSavedAccessToken(); // Grab the fresh token
        } else {
          return handler.reject(
            DioException(requestOptions: options, error: 'Session expired'),
          );
        }
      }

      // Inject the valid token into headers
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  // 2. IF A 401 UNAUTHORIZED STILL HAPPENS (Reactive Catch)
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Catch 401 status codes from the server
    if (err.response?.statusCode == 401) {
      final bool refreshSuccess = await _handleTokenRefresh();

      if (refreshSuccess) {
        final String? newToken = _getSavedAccessToken();

        // Clone the original request configuration and swap the header
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $newToken';

        try {
          // Retry the request with the updated token
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response); // Complete the request successfully
        } on DioException catch (retryError) {
          return handler.next(retryError); // Fail if the retry fails
        }
      } else {
        // Token refresh failed, likely due to an invalid refresh token or server issue
        // Here you could also trigger a logout or redirect to login screen if needed
      }
    }

    return handler.next(err);
  }

  String? _getSavedAccessToken() {
    return sdkProvider.initSessionResponse?.sessionToken;
  }

  Future<bool> _handleTokenRefresh() async {
    try {
      return (await sdkProvider.initiateSession(refresh: true)) != null;
    } catch (e) {
      return false;
    }
  }
}

// Display error code sample
// try {
//   final response = await dio.get('/some-endpoint');
//   // handle success
// } on DioException catch (e) {
//   final message = e.error?.toString() ?? e.message ?? 'Unknown error';
//   if (message.contains('Session expired')) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Session expired. Please log in again.')),
//     );
//   }
//   rethrow;
// }
