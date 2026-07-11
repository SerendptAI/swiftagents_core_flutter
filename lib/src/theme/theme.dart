import 'package:flutter/material.dart';

class SwiftAgentsThemeData {
  final Color sidebarBg;
  final Color userBubble;
  final Color agentBubble;
  final Color background;
  final Color foreground;
  final Color border;
  final Widget? avatar;

  const SwiftAgentsThemeData({
    this.sidebarBg = const Color(0xFF8AA0FF),
    this.userBubble = const Color(0xFF006BE5),
    this.agentBubble = const Color(0xFFF2F8FF),
    this.background = Colors.white,
    this.foreground = const Color(0xFF000000),
    this.border = const Color(0x0F000000),
    this.avatar,
  });

  factory SwiftAgentsThemeData.dark() {
    return const SwiftAgentsThemeData(
      background: Color(0xFF303030),
      foreground: Colors.white,
      border: Color(0xFF303030),
    );
  }

  factory SwiftAgentsThemeData.light() {
    return const SwiftAgentsThemeData();
  }
}

class SwiftAgentsTheme extends InheritedWidget {
  final SwiftAgentsThemeData data;

  const SwiftAgentsTheme({super.key, required this.data, required super.child});

  static SwiftAgentsThemeData of(BuildContext context) {
    final t = context.dependOnInheritedWidgetOfExactType<SwiftAgentsTheme>();
    return t?.data ?? SwiftAgentsThemeData();
  }

  @override
  bool updateShouldNotify(SwiftAgentsTheme oldWidget) => oldWidget.data != data;
}
