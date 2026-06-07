import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../swift_agents.dart';

class CustomShimmer extends StatelessWidget {
  final double height;
  final int? itemCount;
  final ScrollPhysics? physics;
  final double topPadding;

  const CustomShimmer({
    super.key,
    this.height = 200,
    this.itemCount = 10,
    this.physics,
    this.topPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);

    return SizedBox(
      height: height,
      child: ListView.builder(
        itemCount: itemCount,
        physics: physics,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? topPadding : 8),
            child: Shimmer.fromColors(
              baseColor: t.sidebarBg, // Light gray background
              highlightColor: Colors.grey[100]!, // Lighter gray shimmer
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Container(height: 30, color: Colors.black12),
              ),
            ),
          );
        },
      ),
    );
  }
}
