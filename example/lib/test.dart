// // Gemini
// import 'package:flutter/material.dart';
// import '../theme/theme.dart';
// import '../screens/home_screen.dart';
// import '../screens/sidebar.dart';
//
// class SwiftAgents extends StatefulWidget {
//   final SwiftAgentsThemeData? theme;
//   final Widget? initialScreen;
//
//   const SwiftAgents({super.key, this.theme, this.initialScreen});
//
//   @override
//   State<SwiftAgents> createState() => _SwiftAgentsState();
// }
//
// class _SwiftAgentsState extends State<SwiftAgents> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   final int sidebarMilliSecond = 260;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: sidebarMilliSecond),
//     );
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   void _toggleSidebar() {
//     if (_animationController.isCompleted) {
//       _animationController.reverse();
//     } else {
//       _animationController.forward();
//     }
//   }
//
//   // Handles manual drag/swipe gestures
//   void _handleDragUpdate(DragUpdateDetails details, double maxSlide) {
//     // Convert the delta movement into a 0.0 -> 1.0 value for the controllers
//     _animationController.value += details.primaryDelta! / maxSlide;
//   }
//
//   // Handles snapping when the user releases their finger
//   void _handleDragEnd(DragEndDetails details, double maxSlide) {
//     if (_animationController.isAnimating || _animationController.isCompleted) return;
//
//     // Snap based on swipe velocity or how far they dragged (past 50% threshold)
//     if (details.velocity.pixelsPerSecond.dx > 365) {
//       _animationController.forward(); // Swift swipe right opens
//     } else if (details.velocity.pixelsPerSecond.dx < -365) {
//       _animationController.reverse(); // Swift swipe left closes
//     } else if (_animationController.value > 0.5) {
//       _animationController.forward();
//     } else {
//       _animationController.reverse();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = widget.theme ?? SwiftAgentsThemeData();
//     final screenWidth = MediaQuery.sizeOf(context).width;
//
//     // Calculate 40% of the screen width for the sidebar exposure
//     final double maxSlide = screenWidth * 0.4;
//
//     return SwiftAgentsTheme(
//       data: theme,
//       child: SafeArea(
//         top: false,
//         child: DraggableScrollableSheet(
//           initialChildSize: 0.92,
//           minChildSize: 0.5,
//           maxChildSize: 0.97,
//           expand: false,
//           builder: (context, scrollController) {
//             // AnimatedBuilder rebuilds efficiently only when the animation values change
//             return AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 // Calculate current slide offset and border radius based on animation state
//                 double slide = maxSlide * _animationController.value;
//                 double scale = 1.0; // Optional: You could scale down slightly if desired (e.g., 1.0 - (0.05 * _animationController.value))
//                 double borderRadius = 50.0 * _animationController.value;
//
//                 return Stack(
//                   children: [
//                     // 1. BACKGROUND: Sidebar Screen (Constrained to 40% width)
//                     SizedBox(
//                       width: maxSlide,
//                       child: SidebarScreen(
//                         onClose: () => _animationController.reverse(),
//                       ),
//                     ),
//
//                     // 2. FOREGROUND: Main Content with Drag Gestures
//                     Transform.translate(
//                       offset: Offset(slide, 0),
//                       child: Transform.scale(
//                         scale: scale,
//                         alignment: Alignment.centerLeft,
//                         child: GestureDetector(
//                           // Horizontal drag handles manual scrolling
//                           onHorizontalDragUpdate: (details) => _handleDragUpdate(details, maxSlide),
//                           onHorizontalDragEnd: (details) => _handleDragEnd(details, maxSlide),
//                           child: Container(
//                             color: theme.sidebarBg,
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(borderRadius),
//                                 bottomLeft: Radius.circular(borderRadius), // Added bottom left for consistency when sliding
//                               ),
//                               child: Container(
//                                 color: theme.background,
//                                 child: widget.initialScreen ??
//                                     HomeScreen(
//                                       onMenuTap: _toggleSidebar,
//                                       onClose: () => Navigator.of(context).maybePop(),
//                                     ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
//
// // ChatGPT
// class SwiftAgents extends StatefulWidget {
//   final SwiftAgentsThemeData? theme;
//   final Widget? initialScreen;
//
//   const SwiftAgents({
//     super.key,
//     this.theme,
//     this.initialScreen,
//   });
//
//   @override
//   State<SwiftAgents> createState() => _SwiftAgentsState();
// }
//
// class _SwiftAgentsState extends State<SwiftAgents>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//
//   bool get isOpen => _controller.value > 0.5;
//
//   final double maxSlide = 320;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 260),
//     );
//   }
//
//   void toggle() {
//     if (isOpen) {
//       _controller.reverse();
//     } else {
//       _controller.forward();
//     }
//   }
//
//   void onDragUpdate(DragUpdateDetails details) {
//     _controller.value += details.primaryDelta! / maxSlide;
//   }
//
//   void onDragEnd(DragEndDetails details) {
//     if (_controller.value >= 0.5) {
//       _controller.forward();
//     } else {
//       _controller.reverse();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = widget.theme ?? SwiftAgentsThemeData();
//
//     return SwiftAgentsTheme(
//       data: theme,
//       child: SafeArea(
//         top: false,
//         child: DraggableScrollableSheet(
//           initialChildSize: 0.92,
//           minChildSize: 0.5,
//           maxChildSize: 0.97,
//           expand: false,
//           builder: (context, scrollController) {
//             return GestureDetector(
//               onHorizontalDragUpdate: onDragUpdate,
//               onHorizontalDragEnd: onDragEnd,
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 builder: (context, child) {
//                   final slide = maxSlide * _controller.value;
//                   final scale = 1 - (_controller.value * 0.05);
//
//                   return Stack(
//                     children: [
//                       /// Sidebar
//                       Container(
//                         color: theme.sidebarBg,
//                         child: SidebarScreen(
//                           onClose: toggle,
//                         ),
//                       ),
//
//                       /// Main screen
//                       Transform.translate(
//                         offset: Offset(slide, 0),
//                         child: Transform.scale(
//                           scale: scale,
//                           alignment: Alignment.centerLeft,
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.only(
//                               topLeft: Radius.circular(
//                                 50 * _controller.value,
//                               ),
//                             ),
//                             child: Container(
//                               color: theme.background,
//                               child: widget.initialScreen ??
//                                   HomeScreen(
//                                     onMenuTap: toggle,
//                                     onClose: () =>
//                                         Navigator.of(context).maybePop(),
//                                   ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
//
//
// //Grok
// import 'package:flutter/material.dart';
// import 'package:swift_agents/src/constants/colors.dart';
// import '../theme/theme.dart';
// import '../screens/home_screen.dart';
// import '../screens/sidebar.dart';
//
// class SwiftAgents extends StatefulWidget {
//   final SwiftAgentsThemeData? theme;
//   final Widget? initialScreen;
//
//   const SwiftAgents({
//     super.key,
//     this.theme,
//     this.initialScreen,
//   });
//
//   @override
//   State<SwiftAgents> createState() => _SwiftAgentsState();
// }
//
// class _SwiftAgentsState extends State<SwiftAgents> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _animation;
//
//   bool _isSidebarOpen = false;
//   double _dragOffset = 0.0;
//
//   final double _sidebarWidthFactor = 0.4; // 40% of screen width
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 280),
//     );
//
//     _animation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutCubic,
//     );
//   }
//
//   void _toggleSidebar() {
//     setState(() {
//       _isSidebarOpen = !_isSidebarOpen;
//     });
//
//     if (_isSidebarOpen) {
//       _animationController.forward();
//     } else {
//       _animationController.reverse();
//     }
//   }
//
//   void _handleDragUpdate(DragUpdateDetails details, double screenWidth) {
//     final double delta = details.delta.dx / (screenWidth * _sidebarWidthFactor);
//     _dragOffset = (_dragOffset + delta).clamp(0.0, 1.0);
//     _animationController.value = _dragOffset;
//   }
//
//   void _handleDragEnd(DragEndDetails details, double screenWidth) {
//     final double velocity = details.velocity.pixelsPerSecond.dx;
//     final bool shouldOpen = velocity > 300 || _dragOffset > 0.5;
//
//     setState(() {
//       _isSidebarOpen = shouldOpen;
//     });
//
//     if (shouldOpen) {
//       _animationController.forward();
//     } else {
//       _animationController.reverse();
//     }
//
//     // Reset drag offset after animation starts
//     _dragOffset = shouldOpen ? 1.0 : 0.0;
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = widget.theme ?? SwiftAgentsThemeData();
//     final screenWidth = MediaQuery.of(context).size.width;
//     final sidebarWidth = screenWidth * _sidebarWidthFactor;
//
//     return SwiftAgentsTheme(
//       data: theme,
//       child: SafeArea(
//         top: false,
//         child: DraggableScrollableSheet(
//           initialChildSize: 0.92,
//           minChildSize: 0.5,
//           maxChildSize: 0.97,
//           expand: false,
//           builder: (context, scrollController) {
//             return Stack(
//               children: [
//                 // Sidebar
//                 SizedBox(
//                   width: sidebarWidth,
//                   child: SidebarScreen(
//                     onClose: _toggleSidebar,
//                   ),
//                 ),
//
//                 // Main Content with Drag Support
//                 GestureDetector(
//                   onHorizontalDragUpdate: (details) =>
//                       _handleDragUpdate(details, screenWidth),
//                   onHorizontalDragEnd: (details) =>
//                       _handleDragEnd(details, screenWidth),
//                   child: AnimatedBuilder(
//                     animation: _animation,
//                     builder: (context, child) {
//                       final double offset = _animation.value * sidebarWidth;
//
//                       return Transform.translate(
//                         offset: Offset(offset, 0),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: theme.background,
//                             borderRadius: _isSidebarOpen
//                                 ? const BorderRadius.only(
//                               topLeft: Radius.circular(50),
//                             )
//                                 : BorderRadius.zero,
//                           ),
//                           child: widget.initialScreen ??
//                               HomeScreen(
//                                 onMenuTap: _toggleSidebar,
//                                 onClose: () => Navigator.of(context).maybePop(),
//                               ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//
//                 // Scrim (optional but recommended for better UX)
//                 AnimatedBuilder(
//                   animation: _animation,
//                   builder: (context, child) {
//                     return Positioned.fill(
//                       child: IgnorePointer(
//                         ignoring: !_isSidebarOpen,
//                         child: GestureDetector(
//                           onTap: _toggleSidebar,
//                           child: Container(
//                             color: Colors.black.withOpacity(0.25 * _animation.value),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }