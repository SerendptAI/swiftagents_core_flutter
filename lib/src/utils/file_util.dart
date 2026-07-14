import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents_core/src/utils/file_validation_util.dart';
import '../controllers/permissions_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

class FileUtils {
  static String getFileNameFromSignature(String signature) {
    const prefix = 'sw_';

    if (!signature.startsWith(prefix)) {
      return signature;
      // throw ArgumentError('Invalid signature');
    }

    // Remove "sw_"
    final withoutPrefix = signature.substring(prefix.length);

    // Find the first "_" after the hash
    final firstUnderscore = withoutPrefix.indexOf('_');

    if (firstUnderscore == -1) {
      // throw ArgumentError('Invalid signature');
      return signature;
    }

    return withoutPrefix.substring(firstUnderscore + 1);
  }

  String getFileSignature(String name, Uint8List? bytes) {
    String hash = bytes != null
        ? sha256.convert(bytes).toString()
        : Uuid().v4();

    return 'sw_${hash}_$name';
  }

  Future<void> requestPhotoPermission(BuildContext context) async {
    final permissionsProvider = Provider.of<PermissionsProvider>(
      context,
      listen: false,
    );

    if (!(permissionsProvider.isPhotoLibraryEnabled)) {
      await permissionsProvider.requestPhotoLibraryAccess();
    }
  }

  Future<void> requestFileAccessPermission(BuildContext context) async {
    final permissionsProvider = Provider.of<PermissionsProvider>(
      context,
      listen: false,
    );

    if (!(permissionsProvider.isReadStorageEnabled)) {
      await permissionsProvider.requestReadStoragePermission();
    }
  }

  // PICKERS
  Future<List<UploadFile>?> imagesPicker(BuildContext context) async {
    final permissionsProvider = Provider.of<PermissionsProvider>(
      context,
      listen: false,
    );

    final hasPermission = await permissionsProvider.requestPhotoLibraryAccess();

    if (!hasPermission) {
      return null;
    }

    final picker = ImagePicker();

    try {
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 95,
        maxWidth: 2048,
        maxHeight: 1080,
        limit: 5,
      );

      List<UploadFile> imagesAsByte = [];
      for (var xFile in images) {
        final isWithinLimit = FileValidationHelper.isWithinLimit(
          await xFile.length(),
        );
        final imgByte = isWithinLimit ? await xFile.readAsBytes() : null;

        imagesAsByte.add(
          UploadFile(
            bytes: imgByte,
            name: getFileSignature(xFile.name, imgByte),
            size: await xFile.length(),
            isMaxSize: !isWithinLimit,
          ),
        );
      }

      return images.isEmpty ? null : imagesAsByte;
    } catch (e) {
      debugPrint('Image picker error: $e');
      return null;
    }
  }

  Future<UploadFile?> cameraPicker(BuildContext context) async {
    final permissionsProvider = Provider.of<PermissionsProvider>(
      context,
      listen: false,
    );

    final hasPermission = await permissionsProvider.requestPhotoLibraryAccess();

    if (!hasPermission) {
      return null;
    }

    final picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 2048,
        maxHeight: 1080,
      );

      if (image == null) {
        return null;
      }

      final isWithinLimit = FileValidationHelper.isWithinLimit(
        await image.length(),
      );
      final imgByte = isWithinLimit ? await image.readAsBytes() : null;

      return UploadFile(
        bytes: imgByte,
        name: getFileSignature(image.name, imgByte),
        size: await image.length(),
        isMaxSize: !isWithinLimit,
      );
    } catch (e) {
      debugPrint('Camera picker error: $e');
      return null;
    }
  }

  Future<List<UploadFile>?> filesPicker(
    BuildContext context, {
    bool allowMultiple = true,
    int maxFiles = 5,
  }) async {
    final permissionsProvider = Provider.of<PermissionsProvider>(
      context,
      listen: false,
    );

    final hasPermission = await permissionsProvider
        .requestReadStoragePermission();

    if (!hasPermission) {
      return null;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.custom,
        allowedExtensions: [
          "pdf",
          "docx",
          "txt",
          "csv",
          "png",
          "jpg",
          "jpeg",
          "gif",
          "webp",
          "heic",
        ],
        withData: true, // Important for Web
      );

      if (result == null) {
        return null;
      }
      
      return result.files
          .map((pFIle) {
            final isWithinLimit = FileValidationHelper.isWithinLimit(
              pFIle.size,
            );
            final imgByte = isWithinLimit ? pFIle.bytes : null;
            return UploadFile(
              bytes: imgByte,
              name: getFileSignature(pFIle.name, imgByte),
              size: pFIle.size,
              isMaxSize: !isWithinLimit,
            );
          })
          .take(maxFiles)
          .toList();
    } catch (e) {
      debugPrint('File picker error: $e');
      return null;
    }
  }
}

class UploadFile {
  final Uint8List? bytes;
  final String name;
  bool isMaxSize;
  int size;

  UploadFile({
    required this.bytes,
    required this.name,
    required this.size,
    this.isMaxSize = false,
  });

  bool get isImage {
    final ext = name.toLowerCase();

    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp') ||
        ext.endsWith('.heic');
  }
}
