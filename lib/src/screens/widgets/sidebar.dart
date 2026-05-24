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
  final String brand;
  final List<SidebarRecent> recents;

  const SidebarWidget({
    super.key,
    this.onClose,
    this.brand = 'SWIFT AGENTS',
    this.recents = const [
      SidebarRecent('ISSUE WITH NEW FO...', resolved: false),
      SidebarRecent('FIND MY BENEFI...', resolved: true),
      SidebarRecent('RESET PASSWORD', resolved: true),
      SidebarRecent('REPORT A PROBL...', resolved: true),
      SidebarRecent('TRACK MY ORDER', resolved: true),
      SidebarRecent('REFUND STATUS', resolved: true),
      SidebarRecent('CHANGE ADDRESS', resolved: true),
      SidebarRecent('ADD DEPENDENTS', resolved: true),
      SidebarRecent('FILE A CLAIM', resolved: true),
      SidebarRecent('UPLOAD DOCUMEN...', resolved: true),
      SidebarRecent('RENEW BENEFITS'),
      SidebarRecent('CHECK ENROLLME...'),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 32),
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 0);
              },
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
    final t = SwiftAgentsTheme.of(context);
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
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Text(item.label, style: style),
      ),
    );
  }
}
