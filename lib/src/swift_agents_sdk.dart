// lib/src/utils/rive_initializer.dart
import 'package:dio/dio.dart';
import 'package:rive/rive.dart';
import 'package:swift_agents/src/controllers/permissions_provider.dart';
import 'package:swift_agents/src/models/swift_agents_context.dart';
import 'package:swift_agents/src/services/interceptors/api_logger_interceptor.dart';
import 'package:swift_agents/src/services/swift_agents_client.dart';
import 'constants/variables.dart';
import 'controllers/online_provider.dart';
import 'controllers/sdk_provider.dart';

class SwiftAgentsSdk {
  SwiftAgentsSdk._privateConstructor();

  static final SwiftAgentsSdk _instance = SwiftAgentsSdk._privateConstructor();

  factory SwiftAgentsSdk() {
    return _instance;
  }

  static final Map<String, SwiftAgentsContext> _usrContexts = {};

  // Set on initialize
  static String _apiKey = '';
  static String get apiKey => _apiKey;

  static String _companyId = '';
  static String get companyId => _companyId;

  static File? avatarFile;

  static Future<void> _preloadAssets() async {
    // Setup & preload Rive
    avatarFile = await File.asset(
      "packages/${Variables.sdkName}/assets/rives/expressions.riv",
      riveFactory: Factory.rive,
    );
  }

  /// ## Initializes the SwiftAgent SDK
  ///
  /// Call this method inside your `main()` function before running the app.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await SwiftAgentsSdk.initialize(
  ///     companyId: '****',
  ///     apiKey: 'swa_****',
  ///   );
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// The [companyId] is your unique organization identifier found in the dashboard.
  /// The [apiKey] must be a valid public key starting with `swa_`, found in your dashboard.
  static Future<void> initialize({
    required String companyId,
    required String apiKey,
  }) async {
    try {
      await Future.wait([RiveNative.init(), _preloadAssets()]);

      _apiKey = apiKey;
      _companyId = companyId;
    } catch (e) {
      print('SwiftAgents SDK: Failed to initialize - $e');
    }
  }

  /// ## Create or Retrieve user context
  ///
  /// The `getContext` method is a static function that creates or retrieves
  /// a `SwiftAgentsContext` instance for a specific user, identified by their email address.
  /// This ensures that only one context is created per user and reuses the existing
  /// instance if it already exists.
  ///
  /// ### Parameters:
  /// - **`email`** *(required)*: A `String` representing the email address of the user
  ///   for whom the client is being created or retrieved.
  ///
  ///
  /// ### Example Usage:
  /// ```dart
  ///   final context = SwiftAgentsSdk.getContext(email: 'user@example.com');
  ///
  ///   # pass into SwiftAgentsView's context
  ///
  /// ```
  static SwiftAgentsContext getContext({required String email}) {
    if (_companyId.isEmpty || _apiKey.isEmpty) {
      throw (
        SwiftAgentsSDKException(
          'Call SwiftAgentsClient.initialize before getContext().',
        ),
      );
    }

    final client = SwiftAgentsClient(
      email: email,
      dio: Dio(BaseOptions(
          baseUrl: Variables.apiBaseUrl,
        connectTimeout: Duration(seconds: 30),
        receiveTimeout: Duration(seconds: 180),
        followRedirects: false,
      ),
      ),
    );

    client.dio.interceptors.add(ApiLoggerInterceptor());

    return _usrContexts.putIfAbsent(
      email,
      () => SwiftAgentsContext(
        client: client,
        sdkProvider: SdkProvider(client),
        onlineProvider: OnlineProvider(),
        permissionsProvider: PermissionsProvider(),
      ),
    );
  }
}

class SwiftAgentsSDKException implements Exception {
  final String message;

  const SwiftAgentsSDKException(this.message);

  @override
  String toString() => 'SwiftAgentsSDKException: $message';
}

