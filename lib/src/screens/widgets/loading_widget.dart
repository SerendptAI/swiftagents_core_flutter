import 'package:flutter/material.dart';
import 'package:swift_agents_core/src/constants/colors.dart';

class LoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;

  const LoadingWidget({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(color: color ?? kMutedBlue),
      ),
    );
  }
}
