import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents/src/utils/file_validation_util.dart';
import '../controllers/permissions_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

class FileUtils {
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


  Future<List<UploadFile>?> imagesPicker(BuildContext context) async {
    final permissionsProvider = Provider.of<PermissionsProvider>(
      context,
      listen: false,
    );

    final hasPermission = await permissionsProvider.requestPhotoLibraryAccess();

    if (!hasPermission) return null;

    final picker = ImagePicker();

    try {
      final List<XFile> images = await picker.pickMultipleMedia(
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1080,
        limit: 5,
      );

      List<UploadFile> imagesAsByte = [];
      for (var xFile in images) {
        final imgByte = await xFile.readAsBytes();
        imagesAsByte.add(
          UploadFile(
            bytes: await xFile.readAsBytes(),
            name: getFileSignature(xFile.name, imgByte),
            isMaxSize: FileValidationHelper.isWithinLimit(await xFile.length()),
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

    if (!hasPermission) return null;

    final picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        return null;
      }

      final imgByte = await image.readAsBytes();

      return UploadFile(
        bytes: imgByte,
        name: getFileSignature(image.name, imgByte),
        isMaxSize: FileValidationHelper.isWithinLimit(await image.length()),
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

    if (!hasPermission) return null;

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: allowMultiple,
        withData: true, // Important for Web
      );

      if (result == null) return null;

      return result.files
          .map((pFIle) {
            final imgByte = pFIle.bytes;
            return UploadFile(
              bytes: imgByte,
              name: getFileSignature(pFIle.name, imgByte),
              isMaxSize: FileValidationHelper.isWithinLimit(pFIle.size),
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

  UploadFile({required this.bytes, required this.name, this.isMaxSize = false});

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
