import 'dart:async';

import 'package:enhanced_paginated_view/enhanced_paginated_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents/src/controllers/online_provider.dart';
import 'package:swift_agents/src/controllers/sdk_provider.dart';
import 'package:swift_agents/src/models/conversations_response.dart';
import 'package:swift_agents/src/screens/widgets/custom_shimmer.dart';
import '../../../swift_agents.dart';
import '../../constants/fonts.dart';
import '../../constants/variables.dart';

class SidebarWidget extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onNewChat;
  final String brand;

  const SidebarWidget({
    super.key,
    this.onClose,
    this.onNewChat,
    this.brand = 'SWIFT AGENTS',
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  OnlineProvider? onlineProvider;
  StreamSubscription<bool>? _onlineSubscription;

  @override
  void initState() {
    onlineProvider = Provider.of<OnlineProvider>(context, listen: false);
    super.initState();
  }

  @override
  void dispose() {
    _onlineSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    final sdkProvider = Provider.of<SdkProvider>(context);
    final recents = sdkProvider.conversationsList;
    final hasNext = sdkProvider.hasNext;
    final selectedIndex = sdkProvider.selectedConversationIndex;

    void _openChat(ConversationSession recent, int index) {
      if (recent.id != null) {
        // sdkProvider.selectedConversationIndex = index;
        sdkProvider.openChat(recent.id!, index);
        widget.onClose?.call();

        _onlineSubscription?.cancel();
        _onlineSubscription = onlineProvider?.onlineStream.listen((isOnline) {
          if (isOnline && sdkProvider.currentSessionId == recent.id) {
            sdkProvider.initConversationMessagesSock(
              conversationId: recent.id!,
            );
          }
        });
      }
    }

    return Container(
      height: double.maxFinite,
      color: t.sidebarBg,
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 40,
                package: Variables.sdkName,
              ),
              const SizedBox(width: 10),
              Text(
                widget.brand,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: Fonts.dmMono,
                  package: Variables.sdkName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'RECENTS',
            style: TextStyle(
              fontSize: 22,
              fontFamily: Fonts.dmMono,
              fontWeight: FontWeight.w500,
              package: Variables.sdkName,
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: EnhancedPaginatedView(
              hasReachedMax: !hasNext,
              onLoadMore: (int page) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  sdkProvider.getConversations();
                });
              },
              onRefresh: () async {
                await sdkProvider.getConversations(refresh: true);
              },
              refreshBuilder: (context, onRefresh, child) {
                return RefreshIndicator(
                  color: t.sidebarBg,
                  backgroundColor: Colors.grey[100],
                  onRefresh: onRefresh,
                  child: child,
                );
              },
              itemsPerPage: 20,
              delegate: EnhancedDelegate(
                physics: AlwaysScrollableScrollPhysics(),
                listOfData: recents,
                status: EnhancedStatus.loaded,
                emptyWidgetConfig: EmptyWidgetConfig(
                  customView: CustomShimmer(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    topPadding: 10,
                    height: 180,
                  ),
                ),
              ),
              builder: (items, physics, reverse, shrinkWrap) {
                return ListView.separated(
                  physics: physics,
                  reverse: reverse,
                  shrinkWrap: shrinkWrap,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemCount: recents.length,
                  itemBuilder: (context, index) {
                    final recent = recents[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (index == 0 && (selectedIndex == null))
                          _NewChat(
                            onTap: () {
                              widget.onClose?.call();
                            },
                          ),
                        _RecentItem(
                          index: index,
                          selectedIndex: selectedIndex,
                          onTap: () {
                            _openChat(recent, index);
                          },
                          item: recent,
                        ),
                        if (((index + 1) == recents.length) &&
                            sdkProvider.isGetConversationsLoading)
                          CustomShimmer(
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: 2,
                            height: 150,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          /// NEW CHAT BUTTON AT BOTTOM
          InkWell(
            onTap: () {
              widget.onNewChat?.call();
            },
            child: Container(
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    color: Colors.black.withOpacity(0.12),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'NEW CHAT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontFamily: Fonts.dmMono,
                      package: Variables.sdkName,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewChat extends StatefulWidget {
  final void Function() onTap;

  const _NewChat({required this.onTap});

  @override
  State<_NewChat> createState() => _NewChatState();
}

class _NewChatState extends State<_NewChat> {
  bool isSelected = false;
  @override
  void initState() {
    Future.delayed(Duration(milliseconds: 5), () {
      setState(() => isSelected = true);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.black,
      fontFamily: Fonts.dmMono,
      package: Variables.sdkName,
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 40,
        margin: EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('New Chat', overflow: TextOverflow.ellipsis, style: style),
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  final int index;
  final int? selectedIndex;
  final void Function() onTap;
  final ConversationSession item;

  const _RecentItem({
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;

    final style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.black,
      decoration: item.resolved
          ? TextDecoration.lineThrough
          : TextDecoration.none,
      fontFamily: Fonts.dmMono,
      package: Variables.sdkName,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 40,
        margin: EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Opacity(
          opacity: item.resolved ? 0.65 : 1,
          child: Text(
            item.subject ?? item.lastMessage ?? item.type ?? '',
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ),
    );
  }
}
