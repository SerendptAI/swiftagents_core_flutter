// lib/src/utils/rive_initializer.dart
import 'package:dio/dio.dart';
import 'package:rive/rive.dart';
import 'package:swift_agents/src/services/swift_agents_client.dart';
import 'constants/variables.dart';

class SwiftAgentsSdk {
  SwiftAgentsSdk._privateConstructor();

  static final SwiftAgentsSdk _instance = SwiftAgentsSdk._privateConstructor();

  factory SwiftAgentsSdk() {
    return _instance;
  }

  static Map<String, SwiftAgentsClient> _usrClients = {};
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
  ///
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

  /// ## Create or Retrieve a Client
  ///
  /// The `getClient` method is a static function that creates or retrieves
  /// a `SwiftAgentsClient` instance for a specific user, identified by their email address.
  /// This ensures that only one client instance is created per user and reuses the existing
  /// instance if it already exists.
  ///
  /// ### Parameters:
  /// - **`email`** *(required)*: A `String` representing the email address of the user
  ///   for whom the client is being created or retrieved.
  ///
  ///
  /// ### Example Usage:
  /// ```dart
  ///   final client = SwiftAgentsSdk.getClient(email: 'user@example.com');
  ///
  ///   # pass into SwiftAgentsView client
  ///
  /// ```
  static SwiftAgentsClient getClient({required String email}) {
    var usrCli = _usrClients[email];

    if (usrCli == null) {
      final dio = Dio(
        BaseOptions(
          baseUrl: Variables.apiBaseUrl,
          connectTimeout: Duration(seconds: 13),
          receiveTimeout: Duration(seconds: 60),
          followRedirects: false,
        ),
      );

      usrCli = SwiftAgentsClient(
        email: email,
        dio: dio,
      );
    }

    return usrCli;
  }
}
