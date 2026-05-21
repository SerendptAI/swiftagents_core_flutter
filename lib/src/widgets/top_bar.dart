import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:swift_agents/src/constants/colors.dart';
import 'package:swift_agents/src/constants/variables.dart';
import '../constants/fonts.dart';
import '../theme/theme.dart';

class TopBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onClose;
  final String companyName;
  final Widget? logo;

  const TopBar({
    super.key,
    this.onMenuTap,
    this.onClose,
    this.companyName = 'COMPANY NAME',
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
        GestureDetector(
        onTap: onMenuTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.foreground.withOpacity(0.06)),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/svgs/menu.svg',
            package: Variables.sdkName,
            width: 27,
            height: 27,
            colorFilter: ColorFilter.mode(t.foreground, BlendMode.srcIn),
          ),
        ),
      ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  color: kLibPurple,
                  alignment: Alignment.center,
                  child: Text(
                    'LOGO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      fontFamily: Fonts.greedNarrow,
                      package: Variables.sdkName,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  companyName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: t.foreground,
                    fontFamily: Fonts.dmMono,
                    package: Variables.sdkName,
                    // fontFamily:
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: SvgPicture.asset(
              'assets/svgs/arrow_down.svg',
              width: 45,
              height: 45,
              package: Variables.sdkName,
              colorFilter: ColorFilter.mode(t.foreground, BlendMode.srcIn),
            ),
            // child: const Icon(Icons.keyboard_arrow_down_outlined, size: 28, weight: .700,),
          ),
        ],
      ),
    );
  }
}


