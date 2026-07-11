import 'package:flutter/material.dart';
import 'package:swift_agents_core/swift_agents_core.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  const GradientText(
    this.text, {
    this.style,
    this.overflow,
    this.textAlign,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);

    final grad =
        gradient ?? LinearGradient(colors: [t.foreground, Colors.white]);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          grad.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, textAlign: textAlign, style: style, overflow: overflow),
    );
  }
}
