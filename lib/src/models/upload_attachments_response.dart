class UploadAttachmentsResponse {
  final List<AttachmentModel>? attachments;

  UploadAttachmentsResponse({this.attachments});

  factory UploadAttachmentsResponse.fromJson(Map<String, dynamic> json) {
    return UploadAttachmentsResponse(
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => AttachmentModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'attachments': attachments?.map((e) => e.toJson()).toList()};
  }
}

class AttachmentModel {
  final String? url;
  final String? type;
  final String? mimeType;
  final String? filename;

  AttachmentModel({this.url, this.type, this.mimeType, this.filename});

  bool get isImage {
    final ext = getFileExtension?.toLowerCase() ?? '';

    return ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'gif' ||
        ext == 'webp' ||
        ext == 'heic';
  }

  @Deprecated(
    'Use fileName instead. Make sure to use FileUtils.getFileNameFromSignature(fileName) to get the main file name when displaying on UI.',
  )
  String? get getFileExtension {
    final rawName = filename ?? url;

    if (rawName == null || rawName.isEmpty) {
      return null;
    }

    final decodedName = Uri.decodeComponent(rawName);
    final candidate = decodedName.contains('/')
        ? decodedName.split('/').last
        : decodedName;
    final normalized = candidate.contains('?')
        ? candidate.split('?').first
        : candidate;
    final withoutSignaturePrefix = normalized.startsWith('sw_')
        ? normalized.substring(normalized.indexOf('_') + 1)
        : normalized;

    final dotIndex = withoutSignaturePrefix.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == withoutSignaturePrefix.length - 1) {
      return null;
    }

    return withoutSignaturePrefix.substring(dotIndex + 1).toLowerCase();
  }

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
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
