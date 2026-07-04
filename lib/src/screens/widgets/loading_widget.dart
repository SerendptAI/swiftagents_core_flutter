import 'package:flutter/material.dart';
import 'package:swift_agents/src/theme/theme.dart';

class LoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;

  const LoadingWidget({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? t.muted,
        ),
      ),
    );
  }
}

