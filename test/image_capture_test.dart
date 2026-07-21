// image_capture_test.dart
//
// Tests CameraService basic behaviour using a stub implementation.
// The old AppStore / ScanVibeState / OcrClient architecture has been replaced
// by Riverpod + Drift; these tests target the CameraService in isolation.

import 'package:flutter_test/flutter_test.dart';
import 'package:scanvibe_pro/src/services/camera_service.dart';

void main() {
  group('CameraService', () {
    test('is not initialized before initialize() is called', () {
      final service = CameraService();
      expect(service.isInitialized, isFalse);
    });

    test('isInitialized is false when no cameras are available', () {
      // We cannot call initialize() in unit tests (no platform),
      // but the default state must be un-initialized.
      final service = CameraService();
      expect(service.isInitialized, isFalse);
      expect(service.currentCamera, isNull);
    });

    test('hasMultipleCameras is false by default (no cameras registered)', () {
      final service = CameraService();
      expect(service.hasMultipleCameras, isFalse);
    });
  });
}
