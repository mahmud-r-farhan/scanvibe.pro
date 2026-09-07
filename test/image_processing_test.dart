import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanvibe_pro/src/services/image_processing_service.dart';

void main() {
  group('ImageProcessingService', () {
    test('imageProcessingServiceProvider provides service', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(imageProcessingServiceProvider);
      expect(service, isNotNull);
      expect(service, isA<ImageProcessingService>());
    });

    test('can instantiate ImageProcessingService', () {
      const service = ImageProcessingService();
      expect(service, isNotNull);
    });
  });
}
