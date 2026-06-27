import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:swift_agents/src/swift_agents_core.dart';

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
    final file = SwiftAgentsCore.avatarFile;

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
      child: RiveWidget(controller: controller, fit: Fit.cover),
    );
  }
}



// class AnimatedAvatarPlayer extends StatefulWidget {
//   final Color? backgroundColor;
//   final Color? foregroundColor;
//
//   const AnimatedAvatarPlayer({
//     super.key,
//     this.backgroundColor,
//     this.foregroundColor,
//   });
//
//   @override
//   State<AnimatedAvatarPlayer> createState() => _AnimatedAvatarPlayerState();
// }
//
// class _AnimatedAvatarPlayerState extends State<AnimatedAvatarPlayer> {
//   late File file;
//   late RiveWidgetController controller;
//   bool isInitialized = false;
//
//   // Track the bound view model instance to update values dynamically
//   ViewModelInstance? _viewModelInstance;
//
//   @override
//   void initState() {
//     super.initState();
//     initRive();
//   }
//
//   void initRive() async {
//     final avatarFile = SwiftAgentsCore.avatarFile;
//     if (avatarFile == null) return;
//
//     // Use your original structure
//     file = avatarFile;
//     controller = RiveWidgetController(file);
//
//     // Initialize data binding from the controller
//     // DataBind.auto() hooks into the default View Model configured in the Rive editor
//     _viewModelInstance = controller.dataBind(DataBind.auto());
//
//     // Apply the initial colors passed down from the parent widget
//     _updateColors();
//
//     setState(() => isInitialized = true);
//   }
//
//   @override
//   void didUpdateWidget(covariant AnimatedAvatarPlayer oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // If the parent widget passes down new colors, dynamically apply them
//     if (isInitialized) {
//       _updateColors();
//     }
//   }
//
//   void _updateColors() {
//     if (_viewModelInstance == null) return;
//
//     // NOTE: 'bgColor' and 'fgColor' must match the EXACT property names
//     // defined by the designer in the Rive Editor's View Model panel.
//     if (widget.backgroundColor != null) {
//       final bgProp = _viewModelInstance!.color('bgColor');
//       if (bgProp != null) bgProp.value = widget.backgroundColor!;
//     }
//
//     if (widget.foregroundColor != null) {
//       final fgProp = _viewModelInstance!.color('fgColor');
//       if (fgProp != null) fgProp.value = widget.foregroundColor!;
//     }
//   }
//
//   @override
//   void dispose() {
//     // Correctly clean up the view model instance and controller to avoid memory leaks
//     _viewModelInstance?.dispose();
//     controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     return SizedBox(
//       width: 80,
//       height: 80,
//       child: RiveWidget(
//         controller: controller,
//         fit: Fit.cover, // Preserved BoxFit behavior from your layout
//       ),
//     );
//   }
// }

