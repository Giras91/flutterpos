import 'package:flutter_test/flutter_test.dart';
import 'package:extropos/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService.importKey validation', () {
    test('invalid base64 throws FormatException', () async {
      final s = SecureStorageService.instance;
      await expectLater(
        s.importKey('not-base64!!'),
        throwsA(isA<FormatException>()),
      );
    });

    test('base64 decodes but wrong length throws FormatException', () async {
      // base64 for 3 bytes [1,2,3]
      final short = 'AQID';
      final s = SecureStorageService.instance;
      await expectLater(s.importKey(short), throwsA(isA<FormatException>()));
    });
  });
}
