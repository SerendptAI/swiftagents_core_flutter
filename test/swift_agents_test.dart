import 'package:flutter_test/flutter_test.dart';

import 'package:swift_agents/src/models/upload_attachments_response.dart';

void main() {
  group('AttachmentModel', () {
    test('derives the file extension from a signed filename', () {
      final attachment = AttachmentModel.fromJson({
        'url': 'https://example.com/download',
        'filename':
            'sw_78a047c3fab9a2f7a23f13aaf30c1fd69c094e7d1e698d24890ca7b71bcc4d3c_UPS.pdf',
      });

      expect(attachment.getFileExtension, 'pdf');
      expect(attachment.isImage, isFalse);
    });

    test('recognizes image extensions from filenames', () {
      final attachment = AttachmentModel.fromJson({
        'filename': 'sw_12345_photo.png',
      });

      expect(attachment.getFileExtension, 'png');
      expect(attachment.isImage, isTrue);
    });
  });
}
