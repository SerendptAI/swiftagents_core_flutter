import 'package:swift_agents/src/controllers/permissions_provider.dart';
import '../controllers/online_provider.dart';
import '../controllers/sdk_provider.dart';
import '../services/swift_agents_client.dart';

class SwiftAgentsContext {
  final SwiftAgentsClient client;
  final SdkProvider sdkProvider;
  final OnlineProvider onlineProvider;
  final PermissionsProvider permissionsProvider;

  SwiftAgentsContext({
    required this.client,
    required this.sdkProvider,
    required this.onlineProvider,
    required this.permissionsProvider,
  });
}