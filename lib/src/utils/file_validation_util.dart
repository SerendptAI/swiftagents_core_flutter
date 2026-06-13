class FileValidationHelper {
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  static bool isWithinLimit(int fileSizeBytes) {
    return fileSizeBytes <= maxFileSizeBytes;
  }

  static double bytesToMb(int bytes) {
    return bytes / (1024 * 1024);
  }

  static String formatSize(int bytes) {
    final mb = bytesToMb(bytes);

    if (mb >= 1) {
      return '${mb.toStringAsFixed(2)} MB';
    }

    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  }
}