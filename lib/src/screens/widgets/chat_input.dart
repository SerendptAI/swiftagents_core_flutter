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
    // Check if file has been selected before
    files.removeWhere(
      (file) => _selectedFiles.any((sfile) => sfile.name == file.name),
    );
    _selectedFiles.addAll(files.take(remainingSlots));
    // Check if files is above Max Size (exceeds 10mb)
    final sFile = List.of(_selectedFiles);
    sFile.removeWhere((sFiles) => sFiles.isMaxSize);
    widget.onAttach?.call(sFile);

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
    setState(() {});
  }

  bool lockMsgSend() {
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);

    final locked =
        !sdkProvider.isInitialized ||
        sdkProvider.isCurrentMsgSending ||
        sdkProvider.isUploadAttachmentsLoading ||
        (!sdkProvider.isNewFilesUploaded && _selectedFiles.isNotEmpty);
    return locked;
  }

  void _send() {
    final isAnyMaxSize = _selectedFiles.any((sFiles) => sFiles.isMaxSize);
    final text = _controller.text.trim();

    if (text.isEmpty || lockMsgSend()) return;

    if (isAnyMaxSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Max file size exceeded (10MB max).')),
      );

      return;
    }

    widget.onSubmit?.call(text);
    _selectedFiles.clear();
    _controller.clear();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
      sdkProvider.clearPreviousUploadedFiles();
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    final sdkProvider = Provider.of<SdkProvider>(context);
    final isMsgSending = sdkProvider.isCurrentMsgSending;
    final isFileUploading = sdkProvider.isUploadAttachmentsLoading;
    final isNewFilesUploaded = sdkProvider.isNewFilesUploaded;

    return Column(
      children: [
        if (_selectedFiles.isNotEmpty)
          Container(
            height: 80,
            margin: EdgeInsets.only(right: 15, left: 15, bottom: 5),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                final isMaxSize = file.isMaxSize;
                final isFileAlreadyUploaded = sdkProvider.previousUploadedFiles
                    .any((pfile) => pfile.filename == file.name);

                return Container(
                  width: 90,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(8),
                    color: t.foreground.withOpacity(0.05),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    alignment: AlignmentGeometry.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: file.isImage && (file.bytes != null)
                              ? Image.memory(file.bytes!, fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file,
                                      color: t.foreground,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        FileUtils.getFileNameFromSignature(
                                          file.name,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: t.foreground,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (isMaxSize || !isFileAlreadyUploaded)
                        Container(
                          color: isMaxSize ? Colors.black54 : Colors.black26,
                          width: 90,
                          height: 90,
                        ),
                      if (!isMaxSize && !isFileAlreadyUploaded)
                        ValueListenableBuilder<double>(
                          valueListenable: sdkProvider.uploadProgress,
                          builder: (context, progress, _) {
                            return CircularProgressIndicator(
                              value: progress,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            );
                          },
                        ),
                      if (isMaxSize)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, color: Colors.grey[100]),
                            SizedBox(height: 3),
                            Text(
                              'File size\nexceeded(10MB max).',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey[100],
                                fontWeight: FontWeight.w600,
                                fontFamily: Fonts.dmMono,
                                package: Variables.sdkName,
                              ),
                            ),
                          ],
                        ),
                      Positioned(
                        right: 3,
                        top: 3,
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
                  ),
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
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: Fonts.stoizi,
                  package: Variables.sdkName,
                ),
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
                      opacity: lockMsgSend() ? 0.5 : 1,
                      child: SvgPicture.asset(
                        'assets/svgs/send.svg',
                        package: Variables.sdkName,
                        width: 33,
                        height: 33,
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
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
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
              child: Container(color: Colors.transparent),
            ),

            Positioned(
              left: position.dx,
              bottom: MediaQuery.of(context).size.height - position.dy + 10,
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
