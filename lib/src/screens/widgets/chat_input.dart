import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents/src/controllers/sdk_provider.dart';

import '../../../swift_agents.dart';
import '../../constants/fonts.dart';
import '../../constants/variables.dart';
import '../../utils/file_util.dart';

class ChatInput extends StatefulWidget {
  final ValueChanged<String>? onSubmit;
  final ValueChanged<List<UploadFile>>? onAttach;
  final ValueChanged<UploadFile>? onRemove;
  final String hintText;

  const ChatInput({
    super.key,
    this.onSubmit,
    this.onAttach,
    this.onRemove,
    this.hintText = 'Ask a question',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  static const int _maxFiles = 5;
  final List<UploadFile> _selectedFiles = [];

  OverlayEntry? _attachmentOverlay;
  final GlobalKey _attachKey = GlobalKey();
  final FileUtils _fileUtils = FileUtils();
  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  void _addFiles(List<UploadFile> files) async {
    final remainingSlots = _maxFiles - _selectedFiles.length;

    if (remainingSlots <= 0) {
      return;
    }
    _selectedFiles.addAll(files.take(remainingSlots));

    widget.onAttach?.call(_selectedFiles);

    setState(() {});
  }

  Future<void> _pickImages() async {
    final files = await _fileUtils.imagesPicker(context);

    if (files == null || files.isEmpty) return;

    _addFiles(files);
  }

  Future<void> _openCamera() async {
    final file = await _fileUtils.cameraPicker(context);

    if (file != null) _addFiles([file]);
  }

  Future<void> _pickFiles() async {
    final files = await _fileUtils.filesPicker(context, maxFiles: _maxFiles);
    if (files == null || files.isEmpty) return;

    _addFiles(files);
  }

  void _removeFile(int index) {
    widget.onRemove?.call(_selectedFiles[index]);
    _selectedFiles.removeAt(index);
    widget.onAttach?.call(_selectedFiles);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text);
    _selectedFiles.clear();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    final sdkProvider = Provider.of<SdkProvider>(context);
    final isMsgSending = sdkProvider.isCurrentMsgSending;

    return Column(
      children: [
        if (_selectedFiles.isNotEmpty)
          Container(
            height: 80,
            margin: EdgeInsets.only(bottom: 14),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];

                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: file.isImage
                            ? Image.memory(file.bytes!, fit: BoxFit.cover)
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.insert_drive_file),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                file.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _removeFile(index),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        Container(
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
                focusNode: _focusNode,
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
                      key: _attachKey,
                      onTap: _toggleAttachmentMenu,
                      child: Icon(
                        Icons.attach_file,
                        size: 22,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _send(),
                    child: Opacity(
                      opacity: isMsgSending ? 0.5: 1,
                      child: SvgPicture.asset(
                        'assets/svgs/send.svg',
                        package: Variables.sdkName,
                        width: 33,
                        height: 33,
                        // colorFilter: ColorFilter.mode(Color(0xFF333333), BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleAttachmentMenu() {
    if (_attachmentOverlay != null) {
      _removeAttachmentMenu();
      return;
    }

    _showAttachmentMenu();
  }

  void _removeAttachmentMenu() {
    _attachmentOverlay?.remove();
    _attachmentOverlay = null;
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    final RenderBox renderBox =
    _attachKey.currentContext!.findRenderObject() as RenderBox;

    final position = renderBox.localToGlobal(Offset.zero);

    _attachmentOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeAttachmentMenu,
              child: Container(
                color: Colors.transparent,
              ),
            ),

            Positioned(
              left: position.dx,
              bottom: MediaQuery.of(context).size.height -
                  position.dy +
                  10,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _menuItem(
                        icon: Icons.camera_alt,
                        title: 'Camera',
                        onTap: () async {
                          _removeAttachmentMenu();
                          await _openCamera();
                        },
                      ),
                      _menuItem(
                        icon: Icons.photo,
                        title: 'Gallery',
                        onTap: () async {
                          _removeAttachmentMenu();
                          await _pickImages();
                        },
                      ),
                      _menuItem(
                        icon: Icons.insert_drive_file,
                        title: 'Files',
                        onTap: () async {
                          _removeAttachmentMenu();
                          await _pickFiles();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_attachmentOverlay!);
  }
}
