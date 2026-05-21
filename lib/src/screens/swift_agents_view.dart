import 'package:flutter/material.dart';
import '../../swift_agents.dart';
import '../screens/home_screen.dart';
import '../widgets/sidebar.dart';
import 'package:provider/provider.dart';

class SwiftAgentsView extends StatefulWidget {
  final SwiftAgentsThemeData? theme;
  final SwiftAgentsSdk client;

  const SwiftAgentsView({super.key, this.theme, required this.client});

  @override
  State<SwiftAgentsView> createState() => _SwiftAgentsViewState();

  void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return this;
          },
        ),
      ),
    );
  }
}

class _SwiftAgentsViewState extends State<SwiftAgentsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final int sidebarMilliSecond = 260;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: sidebarMilliSecond),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  // Handles manual drag/swipe gestures
  void _handleDragUpdate(DragUpdateDetails details, double maxSlide) {
    // Convert the delta movement into a 0.0 -> 1.0 value for the controller
    _animationController.value += details.primaryDelta! / maxSlide;
  }

  // Handles snapping when the user releases their finger
  void _handleDragEnd(DragEndDetails details, double maxSlide) {
    if (_animationController.isAnimating || _animationController.isCompleted)
      return;

    // Snap based on swipe velocity or how far they dragged (past 50% threshold)
    if (details.velocity.pixelsPerSecond.dx > 365) {
      _animationController.forward(); // Swift swipe right opens
    } else if (details.velocity.pixelsPerSecond.dx < -365) {
      _animationController.reverse(); // Swift swipe left closes
    } else if (_animationController.value > 0.5) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? SwiftAgentsThemeData();
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Calculate 40% of the screen width for the sidebar exposure
    final double maxSlide = screenWidth * 0.6;

    return SwiftAgentsTheme(
      data: theme,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: Scaffold(
          body: SwiftAgentsTheme(
            data: theme,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // Calculate current slide offset and border radius based on animation state
                double slide = maxSlide * _animationController.value;
                double scale =
                    1.0; // Optional: You could scale down slightly if desired (e.g., 1.0 - (0.05 * _animationController.value))
                double borderRadius = 50.0 * _animationController.value;

                return Stack(
                  children: [
                    // 1. BACKGROUND: Sidebar Screen (Constrained to 40% width)
                    SizedBox(
                      width: maxSlide,
                      child: SidebarWidget(
                        onClose: () => _animationController.reverse(),
                      ),
                    ),

                    // 2. FOREGROUND: Main Content with Drag Gestures
                    Transform.translate(
                      offset: Offset(slide, 0),
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          // Horizontal drag handles manual scrolling
                          onHorizontalDragUpdate: (details) =>
                              _handleDragUpdate(details, maxSlide),
                          onHorizontalDragEnd: (details) =>
                              _handleDragEnd(details, maxSlide),
                          child: Container(
                            color: theme.sidebarBg,
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(borderRadius),
                              ),
                              child: Container(
                                color: theme.background,
                                child: HomeScreen(
                                      onMenuTap: _toggleSidebar,
                                      onClose: () => Navigator.of(context).maybePop(),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // Calculate current slide offset and border radius based on animation state
              double slide = maxSlide * _animationController.value;
              double scale =
                  1.0; // Optional: You could scale down slightly if desired (e.g., 1.0 - (0.05 * _animationController.value))
              double borderRadius = 50.0 * _animationController.value;

              return Stack(
                children: [
                  // 1. BACKGROUND: Sidebar Screen (Constrained to 40% width)
                  SizedBox(
                    width: maxSlide,
                    child: SidebarWidget(
                      onClose: () => _animationController.reverse(),
                    ),
                  ),

                  // 2. FOREGROUND: Main Content with Drag Gestures
                  Transform.translate(
                    offset: Offset(slide, 0),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        // Horizontal drag handles manual scrolling
                        onHorizontalDragUpdate: (details) =>
                            _handleDragUpdate(details, maxSlide),
                        onHorizontalDragEnd: (details) =>
                            _handleDragEnd(details, maxSlide),
                        child: Container(
                          color: theme.sidebarBg,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(borderRadius),
                            ),
                            child: Container(
                              color: theme.background,
                              child: HomeScreen(
                                    onMenuTap: _toggleSidebar,
                                    onClose: () => Navigator.of(context).maybePop(),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

