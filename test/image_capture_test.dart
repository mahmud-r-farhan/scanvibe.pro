import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanvibe_pro/src/app.dart';
import 'package:scanvibe_pro/src/services/app_store.dart';
import 'package:scanvibe_pro/src/services/image_capture_service.dart';
import 'package:scanvibe_pro/src/services/ocr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppStore store;
  late _FakeOcrClient ocrClient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    store = AppStore(preferences);
    ocrClient = _FakeOcrClient();
  });

  test('successfully captures image and clears previous errors', () async {
    final fakeCapture = _FakeImageCaptureService(
      capturedImage: const CapturedImage(path: 'dummy/path.jpg'),
    );
    final state = ScanVibeState(
      store: store,
      ocrClient: ocrClient,
      imageCaptureService: fakeCapture,
    );

    expect(state.captureError, isNull);
    expect(state.isCameraAvailable, isTrue);

    await state.createDocumentFromCamera();

    expect(state.captureError, isNull);
    expect(state.documents, hasLength(1));
  });

  test('handles no_available_camera exception', () async {
    final fakeCapture = _FakeImageCaptureService(
      exception: PlatformException(
        code: 'no_available_camera',
        message: 'No camera',
      ),
    );
    final state = ScanVibeState(
      store: store,
      ocrClient: ocrClient,
      imageCaptureService: fakeCapture,
    );

    expect(state.isCameraAvailable, isTrue);
    expect(state.captureError, isNull);

    await state.createDocumentFromCamera();

    expect(state.isCameraAvailable, isFalse);
    expect(state.captureError, equals('noCameraError'));
  });

  test('handles camera_access_denied exception', () async {
    final fakeCapture = _FakeImageCaptureService(
      exception: PlatformException(
        code: 'camera_access_denied',
        message: 'Access denied',
      ),
    );
    final state = ScanVibeState(
      store: store,
      ocrClient: ocrClient,
      imageCaptureService: fakeCapture,
    );

    await state.createDocumentFromCamera();

    expect(
      state.isCameraAvailable,
      isTrue,
    ); // only set false on no_available_camera
    expect(state.captureError, equals('cameraPermissionError'));
  });

  test('clears capture error on request', () async {
    final fakeCapture = _FakeImageCaptureService(
      exception: PlatformException(
        code: 'photo_access_denied',
        message: 'Gallery denied',
      ),
    );
    final state = ScanVibeState(
      store: store,
      ocrClient: ocrClient,
      imageCaptureService: fakeCapture,
    );

    await state.importDocumentFromGallery();
    expect(state.captureError, equals('galleryPermissionError'));

    state.clearCaptureError();
    expect(state.captureError, isNull);
  });
}

class _FakeImageCaptureService implements ImageCaptureService {
  _FakeImageCaptureService({this.capturedImage, this.exception});

  final CapturedImage? capturedImage;
  final Object? exception;

  @override
  Future<CapturedImage?> pick(ImageSourceKind source) async {
    if (exception != null) {
      throw exception!;
    }
    return capturedImage;
  }
}

class _FakeOcrClient implements OcrClient {
  @override
  Future<OcrResult> extractText({
    required String imagePath,
    required String languageHint,
  }) async {
    return const OcrResult(text: 'dummy text', confidence: 0.9);
  }
}
