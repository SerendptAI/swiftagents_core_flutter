import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../swift_agents.dart';

class AnimatedAvatarPlayer extends StatefulWidget {
  const AnimatedAvatarPlayer({super.key});

  @override
  State<AnimatedAvatarPlayer> createState() => _AnimatedAvatarPlayerState();
}

class _AnimatedAvatarPlayerState extends State<AnimatedAvatarPlayer> {
  late File file;
  late RiveWidgetController controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    initRive();
  }

  void initRive() async {
    final file = SwiftAgentsSdk.avatarFile;
    if (file == null) return;

    controller = RiveWidgetController(file);
    setState(() => isInitialized = true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox(
      width: 80,
      height: 80,
      child: RiveWidget(
        controller: controller,
        fit: Fit.cover,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
//
// import '../../swift_agents.dart';
// import '../constants/variables.dart';
//
// class AnimatedAvatarPlayer extends StatefulWidget {
//   const AnimatedAvatarPlayer({super.key});
//
//   @override
//   State<AnimatedAvatarPlayer> createState() =>
//       _AnimatedAvatarPlayerState();
// }
//
// class _AnimatedAvatarPlayerState
//     extends State<AnimatedAvatarPlayer> {
//   bool isInited = false;
//   late final VideoPlayerController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = VideoPlayerController.asset(
//       'packages/${Variables.sdkName}/assets/videos/expressions.mp4',
//       videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
//     )
//       ..setLooping(true)
//       ..setVolume(0)
//       ..initialize().then((_) {
//         if (mounted) {
//           setState(() => isInited = true);
//         }
//         _controller.play();
//       });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final t = SwiftAgentsTheme.of(context);
//
//     return Container(
//       width: 64,
//       height: 64,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: isInited ? null: Border.all(
//           color: t.foreground,
//           width: 3,
//         ),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: _controller.value.isInitialized
//           ? FittedBox(
//         fit: BoxFit.cover,
//         child: SizedBox(
//           width: _controller.value.size.width,
//           height: _controller.value.size.height,
//           child: VideoPlayer(_controller),
//         ),
//       )
//           : const SizedBox.shrink(),
//     );
//   }
// }
