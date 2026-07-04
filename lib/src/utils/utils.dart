import 'dart:convert';
import 'package:intl/intl.dart';

class Utils {
  DateTime? getJwtExpiryTime(String token) {
    try {
      // 1. Split the token into its 3 parts (Header, Payload, Signature)
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // 2. Normalize and pad the Base64 URL encoded payload
      String payloadPart = parts[1];
      payloadPart = payloadPart.replaceAll('-', '+').replaceAll('_', '/');
      switch (payloadPart.length % 4) {
        case 2:
          payloadPart += '==';
          break;
        case 3:
          payloadPart += '=';
          break;
      }

      // 3. Decode the base64 string to a UTF-8 string, then parse to JSON
      final String decodedString = utf8.decode(base64Url.decode(payloadPart));
      final Map<String, dynamic> payload = jsonDecode(decodedString);

      // 4. Extract 'exp' claim and convert from seconds to DateTime
      if (payload.containsKey('exp')) {
        final int expInSeconds = payload['exp'] as int;
        // Convert Unix epoch seconds to a DateTime object (UTC)
        final DateTime expiryUtc = DateTime.fromMillisecondsSinceEpoch(
          expInSeconds * 1000,
          isUtc: true,
        );
        // Convert to local time zone
        return expiryUtc.toLocal();
      }

      return null; // 'exp' claim not found
    } catch (e) {
      return null; // Malformed token or decode error
    }
  }

  String formatDateTime(DateTime dateTime) {
    final date = dateTime.toLocal();
    final now = DateTime.now();

    final time = DateFormat('h:mm a').format(date);

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      return time;
    }

    final difference = now.difference(date).inDays;

    if (difference < 7) {
      return '$time Today';
    }

    return '$time ${DateFormat('M/d/yy').format(date)}';
  }
}
