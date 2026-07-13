import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanvibe_pro/src/app.dart';
import 'package:scanvibe_pro/src/l10n/scanvibe_localizations.dart';
import 'package:scanvibe_pro/src/services/app_store.dart';
import 'package:scanvibe_pro/src/services/image_capture_service.dart';
import 'package:scanvibe_pro/src/services/ocr_client.dart';
import 'package:scanvibe_pro/src/ui/screens/scan_screen.dart';
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

  Widget createWidgetUnderTest(ScanVibeState state) {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [_FakeLocalizationsDelegate()],
      home: ScanScreen(state: state),
    );
  }

  testWidgets('renders initial scan screen correctly', (tester) async {
    final state = ScanVibeState(store: store, ocrClient: ocrClient);

    await tester.pumpWidget(createWidgetUnderTest(state));
    await tester.pump();

    expect(find.text('Create New Document'), findsOneWidget);
    expect(
      find.text('Choose a source to scan and extract text.'),
      findsOneWidget,
    );
    expect(find.byType(ScannerViewport), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets('shows and dismisses capture error banner', (tester) async {
    final fakeCapture = _FakeImageCaptureService(exception: Exception('Fail'));
    final state = ScanVibeState(
      store: store,
      ocrClient: ocrClient,
      imageCaptureService: fakeCapture,
    );

    await tester.pumpWidget(createWidgetUnderTest(state));
    await tester.pump();

    // Trigger error
    await state.createDocumentFromCamera();
    await tester.pump();

    // Verify error banner is visible
    expect(find.text('Failed to capture or import image.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    // Tap dismiss
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    // Verify error banner is gone
    expect(find.text('Failed to capture or import image.'), findsNothing);
  });

  testWidgets('shows warning and disables camera button when camera unavailable', (
    tester,
  ) async {
    final fakeCapture = _FakeImageCaptureService(
      // no_available_camera sets availability to false
      exception: Exception('No camera'),
    );
    final state = ScanVibeState(
      store: store,
      ocrClient: ocrClient,
      imageCaptureService: fakeCapture,
    );

    // Manually trigger the no_available_camera flow or set it
    // Wait, the handler sets it. Let's trigger a pick that fails with no_available_camera
    await state
        .createDocumentFromCamera(); // This is a general exception. To set isCameraAvailable = false, we need PlatformException.

    // Let's create a specific state with PlatformException
    final platformFake = _FakeImageCaptureService(
      exception: _createPlatformException('no_available_camera'),
    );
    final platformState = ScanVibeState(
      store: store,
      ocrClient: ocrClient,
      imageCaptureService: platformFake,
    );

    await tester.pumpWidget(createWidgetUnderTest(platformState));
    await tester.pump();

    await platformState.createDocumentFromCamera();
    await tester.pump();

    // Warn banner should be displayed
    expect(
      find.text(
        'Camera is unavailable. Try importing from your gallery instead.',
      ),
      findsOneWidget,
    );

    // Camera button should show "(failed)" or disabled label
    expect(find.text('Camera (Failed)'), findsOneWidget);

    // Gallery button should still be enabled
    expect(find.text('Gallery'), findsOneWidget);
  });
}

Exception _createPlatformException(String code) {
  return PlatformException(code: code, message: 'Mock Platform Exception');
}

class _FakeImageCaptureService implements ImageCaptureService {
  _FakeImageCaptureService({this.exception});

  final Object? exception;

  @override
  Future<CapturedImage?> pick(ImageSourceKind source) async {
    if (exception != null) {
      throw exception!;
    }
    return const CapturedImage(path: 'dummy.jpg');
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

class _FakeLocalizationsDelegate
    extends LocalizationsDelegate<ScanVibeLocalizations> {
  const _FakeLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<ScanVibeLocalizations> load(Locale locale) async {
    return ScanVibeLocalizations(const Locale('en'));
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<ScanVibeLocalizations> old,
  ) => false;
}
