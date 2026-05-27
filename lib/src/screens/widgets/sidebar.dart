import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../swift_agents.dart';
import '../../constants/fonts.dart';
import '../../constants/variables.dart';

class SidebarRecent {
  final String label;
  final bool resolved;

  const SidebarRecent(this.label, {this.resolved = false});
}

class SidebarWidget extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onNewChat;
  final String brand;
  final List<SidebarRecent> recents;

  const SidebarWidget({
    super.key,
    this.onClose,
    this.onNewChat,
    this.brand = 'SWIFT AGENTS',
    this.recents = const [
      SidebarRecent('ISSUE WITH NEW FO...', resolved: false),
      SidebarRecent('FIND MY BENEFI...', resolved: true),
      SidebarRecent('RESET PASSWORD', resolved: true),
      SidebarRecent('REPORT A PROBL...', resolved: true),
      SidebarRecent('TRACK MY ORDER', resolved: true),
      SidebarRecent('REFUND STATUS', resolved: true),
      SidebarRecent('CHANGE ADDRESS', resolved: true),
      SidebarRecent('UPLOAD DOCUMEN...', resolved: true),
      SidebarRecent('RENEW BENEFITS'),
    ],
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);

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
              itemCount: widget.recents.length,
              itemBuilder: (context, index) {
                return _RecentItem(
                  index: index,
                  selectedIndex: selectedIndex,
                  onTap: () {
                    setState(() => selectedIndex = index);
                  },
                  item: widget.recents[index],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          /// NEW CHAT BUTTON AT BOTTOM
          InkWell(
            onTap: widget.onNewChat,
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
                  const Icon(
                    Icons.add_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
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
  final int selectedIndex;
  final void Function() onTap;
  final SidebarRecent item;

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
          item.label,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}