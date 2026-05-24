import '../controllers/online_provider.dart';
import '../controllers/sdk_provider.dart';
import '../services/swift_agents_client.dart';

class SwiftAgentsContext {
  final SwiftAgentsClient client;
  final SdkProvider sdkProvider;
  final OnlineProvider onlineProvider;

  SwiftAgentsContext({
    required this.client,
    required this.sdkProvider,
    required this.onlineProvider,
  });
}