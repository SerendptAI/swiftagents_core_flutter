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