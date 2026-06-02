import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents/src/controllers/sdk_provider.dart';
import 'package:swift_agents/src/models/conversations_response.dart';

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
  int? selectedIndex;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_paginationListener);
  }

  void _paginationListener() {
    final provider = context.read<SdkProvider>();

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isGetConversionsLoading && provider.hasNext) {
        provider.getConversations();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    final sdkProvider = Provider.of<SdkProvider>(context);
    final recents = sdkProvider.conversationsList;
    final hasNext = sdkProvider.hasNext;

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
            child: ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemCount: recents.length + (hasNext ? 0 : 0),
              itemBuilder: (context, index) {
                final recent = recents[index];
                if (index == recents.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return _RecentItem(
                  index: index,
                  selectedIndex: selectedIndex,
                  onTap: () {
                    if (recent.id != null) {
                      setState(() => selectedIndex = index);
                      sdkProvider.openChat(recent.id!);
                    }
                  },
                  item: recent,
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          /// NEW CHAT BUTTON AT BOTTOM
          InkWell(
            onTap: () {
              widget.onNewChat?.call();
              selectedIndex = null;
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

class _RecentItem extends StatelessWidget {
  final int index;
  final int? selectedIndex;
  final void Function() onTap;
  final ConversationItem item;

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
        child: Text(
          item.lastMessage ?? '',
          // item.subject ?? '',
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}
