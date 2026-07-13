import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents_core/src/controllers/sdk_provider.dart';
import 'package:swift_agents_core/src/models/swift_agents_context.dart';
import 'package:swift_agents_core/src/screens/widgets/sidebar.dart';
import '../../swift_agents_core.dart';
import '../controllers/online_provider.dart';
import '../theme/theme.dart';
import '../screens/home_screen.dart';

class SwiftAgentsView extends StatelessWidget {
  final SwiftAgentsThemeData? theme;
  final SwiftAgentsContext sdkContext;

  const SwiftAgentsView({super.key, this.theme, required this.sdkContext});

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

  @override
  Widget build(BuildContext context) {
    final ctxSdkProvider = sdkContext.sdkProvider;
    final ctxOnlineProvider = sdkContext.onlineProvider;
    final ctxPermissionsProvider = sdkContext.permissionsProvider;

    return SwiftAgentsTheme(
      data: theme ?? SwiftAgentsThemeData.light(),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ctxSdkProvider),
          ChangeNotifierProvider.value(value: ctxOnlineProvider),
          ChangeNotifierProvider.value(value: ctxPermissionsProvider),
        ],
        child: _SwiftAgentsViewBody(theme: theme),
      ),
    );
  }
}

class _SwiftAgentsViewBody extends StatefulWidget {
  final SwiftAgentsThemeData? theme;

  const _SwiftAgentsViewBody({required this.theme});

  @override
  State<_SwiftAgentsViewBody> createState() => _SwiftAgentsViewBodyState();
}

class _SwiftAgentsViewBodyState extends State<_SwiftAgentsViewBody>
    with SingleTickerProviderStateMixin {
  final int sidebarMilliSecond = 260;
  OnlineProvider? onlineProvider;

  late AnimationController _animationController;

  void init() async {
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    await sdkProvider.initiateSession();

    final session = sdkProvider.initSessionResponse;
    if (session != null) {
      sdkProvider.initConversationsSock();
      sdkProvider.getConversations(checkConversationsLoaded: true);
      sdkProvider.initConversationMessagesSock(
        conversationId: sdkProvider.currentSessionId,
      );
    }
  }

  void checkInternetConnection() {
    onlineProvider = Provider.of<OnlineProvider>(context, listen: false);
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);

    if (sdkProvider.messages.isEmpty) {
      sdkProvider.createNewChat(enableMsgSocket: false);
    }

    if (onlineProvider?.isOnline ?? false) init();

    onlineProvider?.onlineStream.listen((bool isOnline) async {
      if (isOnline) {
        init();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkInternetConnection();
    });

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
    // Convert the delta movement into a 0.0 -> 1.0 value for the controllers
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

    // Calculate 60% of the screen width for the sidebar exposure
    final double maxSlide = screenWidth * 0.6;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Calculate current slide offset and border radius based on animation state
          double slide = maxSlide * _animationController.value;
          double scale =
              1.0; // Optional: You could scale down slightly if desired (e.g., 1.0 - (0.05 * _animationController.value))
          double borderRadius = 50.0 * _animationController.value;

          return ClipRect(
            child: SizedBox(
              width: screenWidth,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // 1. BACKGROUND: Sidebar Screen (Constrained to 40% width)
                  SizedBox(
                    width: maxSlide,
                    child: SidebarWidget(
                      onClose: () =>
                          Future.delayed(Duration(microseconds: 800), () {
                            _animationController.reverse();
                          }),
                      onNewChat: () {
                        final sdkProvider = context.read<SdkProvider>();
                        sdkProvider.createNewChat(
                          enableMsgSocket: onlineProvider?.isOnline ?? false,
                        );
                        Future.delayed(Duration(microseconds: 800), () {
                          _animationController.reverse();
                        });
                      },
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
              ),
            ),
          );
        },
      ),
    );
  }
}
