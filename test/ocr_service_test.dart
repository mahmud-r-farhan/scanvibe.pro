import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanvibe_pro/src/services/ocr_service.dart';

void main() {
  group('OcrResult and OcrException', () {
    test('OcrResult stores text and confidence properly', () {
      const result = OcrResult(
        text: 'Invoice #12345\nTotal: \$99.00',
        confidence: 0.94,
      );
      expect(result.text, contains('Invoice #12345'));
      expect(result.confidence, 0.94);
      expect(result.blocks, isEmpty);
    });

    test('OcrResult defaults confidence to 0.0', () {
      const result = OcrResult(text: 'Hello');
      expect(result.confidence, 0.0);
    });

    test('OcrException formats message cleanly in toString', () {
      const exception = OcrException('Camera frame is blank');
      expect(exception.message, 'Camera frame is blank');
      expect(exception.toString(), 'OcrException: Camera frame is blank');
    });

    test('ocrServiceProvider can be read in ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(ocrServiceProvider);
      expect(service, isNotNull);
      expect(service, isA<OcrService>());
    });
  });
}
