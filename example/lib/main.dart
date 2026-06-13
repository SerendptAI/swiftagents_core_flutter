import 'package:flutter/material.dart';
import 'package:swift_agents/swift_agents.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SwiftAgentsSdk.initialize(
    companyId: 'your_company_id',
    apiKey: 'your_api_key',
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'SwiftAgents Demo',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    home: const HomePage(),
    );
    }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sdkContext = SwiftAgentsSdk.getContext(email: 'user@email.com');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text('Serendpt app'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          SwiftAgentsView(
              sdkContext: sdkContext
          ).show(context);
        },
        child: const Icon(Icons.wechat_outlined),
      ),
      body: Center(
        child: MaterialButton(
          color: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SafeArea(
                  child: SwiftAgentsView(
                    theme: SwiftAgentsThemeData.dark(),
                    sdkContext: sdkContext,
                  ),
                ),
              ),
            );
          },
          child: const Text('Try Dark Mode'),
        ),
      ),
    );
  }
}
