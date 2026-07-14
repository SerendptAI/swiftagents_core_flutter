import 'package:flutter/material.dart';
import 'package:swift_agents_core/src/constants/fonts.dart';
import 'package:swift_agents_core/src/constants/variables.dart';
import 'package:swift_agents_core/src/screens/widgets/gradient_text.dart';
import 'package:swift_agents_core/src/screens/widgets/loading_widget.dart';
import 'package:swift_agents_core/swift_agents_core.dart';

class ButtonFilled extends StatelessWidget {
  final String text;
  final Color? textColor;
  final TextStyle? textStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? gradientButtonTextColor;
  final double? width;
  final double? height;
  final Widget? leading;
  final Widget? trailing;
  final double? leadingWidth;
  final double? trailingWidth;
  final BorderSide? borderSide;
  final Color? backgroundColor;
  final VoidCallback onPressed;
  final Gradient gradient;
  final bool enableGradient;
  final bool enableTextGradient;
  final bool isLoading;
  final bool outlined;
  final Color? outlineColor;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadows;

  const ButtonFilled({
    super.key,
    this.leading,
    this.trailing,
    this.textStyle,
    required this.text,
    this.backgroundColor,
    required this.onPressed,
    this.textColor = Colors.white, // Colors.grey[800]
    this.gradientButtonTextColor = Colors.white,
    this.borderSide,
    this.height = 50,
    this.fontSize = 14,
    this.leadingWidth = 15,
    this.trailingWidth = 15,
    this.isLoading = false,
    this.outlined = false,
    this.outlineColor,
    this.enableGradient = false,
    this.width = double.maxFinite,
    this.enableTextGradient = false,
    this.fontWeight = FontWeight.w600,
    this.gradient = const LinearGradient(colors: [Colors.red, Colors.green]),
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
    this.margin = const EdgeInsets.symmetric(horizontal: 10),
    this.boxShadows = const [
      BoxShadow(
        color: Colors.black38,
        blurRadius: 10,
        offset: Offset(2, 2), // changes position of shadow
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);

    BorderSide getBorderSide() {
      if (borderSide != null) {
        return borderSide!;
      } else if (outlined) {
        return BorderSide(color: outlineColor ?? t.foreground, width: 1);
      }

      return BorderSide.none;
    }

    getBackgroundColor() {
      if (outlined && backgroundColor == null) {
        return Colors.transparent;
      } else if (enableGradient) {
        return null;
      } else if (backgroundColor == null) {
        return t.foreground;
      } else {
        return backgroundColor;
      }
    }

    // Color? getTextColor() {
    //   if (outlined && backgroundColor == null) {
    //     return Colors.transparent;
    //   } else if (enableGradient) {
    //     return gradientButtonTextColor;
    //   } else if (outlined) {
    //     return kAppOrange;
    //   } else {
    //     return textColor;
    //   }
    // }

    return Padding(
      padding: margin,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: enableGradient ? gradient : null,
          color: getBackgroundColor(),
          boxShadow: outlined ? null : boxShadows,
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius:
                  borderRadius ?? BorderRadius.all(Radius.circular(30)),
              side: getBorderSide(),
            ),
          ),
          onPressed: onPressed,
          child: Container(
            height: 35,
            width: width,
            alignment: Alignment.center,
            child: !isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ?leading,
                      if (leading != null) SizedBox(width: leadingWidth),
                      enableTextGradient
                          ? GradientText(
                              text,
                              style:
                                  textStyle ??
                                  TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: fontWeight,
                                    fontFamily: Fonts.dmMono,
                                    package: Variables.sdkName,
                                  ),
                            )
                          : Text(
                              text,
                              style:
                                  textStyle ??
                                  TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: fontWeight,
                                    color: enableGradient
                                        ? gradientButtonTextColor
                                        : textColor,
                                    fontFamily: Fonts.dmMono,
                                    package: Variables.sdkName,
                                  ),
                            ),
                      if (trailing != null) SizedBox(width: trailingWidth),
                      ?trailing,
                    ],
                  )
                : Center(
                    child: LoadingWidget(
                      size: 20,
                      color: enableGradient
                          ? gradientButtonTextColor
                          : textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
