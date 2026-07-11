import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsProvider extends ChangeNotifier {
  bool isReadStorageEnabled = false;
  bool isPhotoLibraryEnabled = false;
  bool isMediaLocationEnabled = false;
  // bool isNotificationEnabled = false;

  PermissionsProvider() {
    initialized();
  }

  Future<void> initialized() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    if (androidInfo.version.sdkInt <= 32) {
      // For Android versions below 33, we treat storage as the source.
      isReadStorageEnabled = await Permission.storage.isGranted;
      isPhotoLibraryEnabled = isReadStorageEnabled; // Unified check for older devices
    } else {
      // For Android 13 and above, we rely on the new photos permission.
      isPhotoLibraryEnabled = await Permission.photos.isGranted;
      // No need to set isReadStorageEnabled, as it’s not used for newer devices.
    }

    isMediaLocationEnabled = await Permission.accessMediaLocation.isGranted;
    // isNotificationEnabled = await Permission.notification.isGranted;

    notifyListeners();
  }

  // ---------------- STORAGE ----------------
  Future<void> checkReadStoragePermission() async {
    var isGranted = await Permission.storage.isGranted;

    if (!isGranted) {
      final status = await Permission.storage.request();
      isGranted = status.isGranted;
    }

    isReadStorageEnabled = isGranted;
    notifyListeners();
  }

  Future<bool> requestReadStoragePermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    if (androidInfo.version.sdkInt <= 32) {
      final status = await Permission.storage.request();

      isReadStorageEnabled = status.isGranted;
      notifyListeners();

      if (!isReadStorageEnabled) {
        await openAppSettings();
      }

      return status.isGranted;
    }

    // Android 13+, iOS, Web
    isReadStorageEnabled = true;
    notifyListeners();
    return true;
  }

  // ---------------- PHOTO LIBRARY ----------------

  Future<bool> requestPhotoLibraryAccess() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    if (androidInfo.version.sdkInt <= 32) {
      final status = await Permission.storage.request();

      isPhotoLibraryEnabled = status.isGranted;
      isReadStorageEnabled = status.isGranted;
      notifyListeners();
      return status.isGranted;
    } else {
      final status = await Permission.photos.request();
      isPhotoLibraryEnabled = status.isGranted;
      notifyListeners();
      return status.isGranted;
    }
  }

  // ---------------- MEDIA IMAGE ----------------

  Future<void> checkAccessMediaLocationPermission() async {
    isMediaLocationEnabled = await Permission.accessMediaLocation.isGranted;
    notifyListeners();
  }

  Future<void> requestAccessMediaLocationPermission() async {
    isMediaLocationEnabled =
        await Permission.accessMediaLocation.request().isGranted;

    notifyListeners();
  }

  // // ---------------- NOTIFICATION ----------------

  // Future<void> checkNotificationPermission() async {
  //   isNotificationEnabled =
  //       await Permission.notification.isGranted;

  //   notifyListeners();
  // }

  // Future<void> requestNotificationPermission() async {
  //   isNotificationEnabled =
  //       await Permission.notification.request().isGranted;

  //   notifyListeners();
  // }
}