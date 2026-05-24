import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../swift_agents.dart';
import '../../constants/fonts.dart';
import '../../constants/variables.dart';

class ChatInput extends StatefulWidget {
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onAttach;
  final String hintText;

  const ChatInput({
    super.key,
    this.onSubmit,
    this.onAttach,
    this.hintText = 'Ask a question',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            onSubmitted: (_) => _send(),
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: t.muted,
                fontSize: 14,
                fontFamily: Fonts.stoizi,
                package: Variables.sdkName,
              ),
              isCollapsed: true,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: GestureDetector(
                  onTap: widget.onAttach,
                  child: Icon(Icons.attach_file, size: 22, color: Color(0xFF1F1F1F),)
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _send(),
                child: SvgPicture.asset(
                  'assets/svgs/send.svg',
                  package: Variables.sdkName,
                  width: 33,
                  height: 33,
                  // colorFilter: ColorFilter.mode(Color(0xFF333333), BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
