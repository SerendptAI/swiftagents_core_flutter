class UploadAttachmentsResponse {
  final List<AttachmentModel>? attachments;

  UploadAttachmentsResponse({
    this.attachments,
  });

  factory UploadAttachmentsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return UploadAttachmentsResponse(
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => AttachmentModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attachments': attachments?.map((e) => e.toJson()).toList(),
    };
  }
}

class AttachmentModel {
  final String? url;
  final String? type;
  final String? mimeType;
  final String? filename;

  AttachmentModel({
    this.url,
    this.type,
    this.mimeType,
    this.filename,
  });

  bool get isImage {
    final ext = url?.toLowerCase() ?? '';

    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp') ||
        ext.endsWith('.heic');
  }

  String? get getFileExtension {
    if (url == null) return null;
    final uri = Uri.parse(url!);
    final filename = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : '';

    final dotIndex = filename.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == filename.length - 1) {
      return null;
    }

    return filename.substring(dotIndex + 1).toLowerCase();
  }

  factory AttachmentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttachmentModel(
      url: json['url'],
      type: json['type'],
      mimeType: json['mime_type'],
      filename: json['filename'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'mime_type': mimeType,
      'filename': filename,
    };
  }
}