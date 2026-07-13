import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:uuid/uuid.dart';

import 'l10n/scanvibe_localizations.dart';
import 'models/scan_document.dart';
import 'services/app_store.dart';
import 'services/document_exporter.dart';
import 'services/image_capture_service.dart';
import 'services/ocr_client.dart';
import 'theme/scanvibe_theme.dart';
import 'ui/home_shell.dart';
import 'ui/onboarding_language_screen.dart';

class ScanVibeApp extends StatelessWidget {
  const ScanVibeApp({super.key, required this.state});

  final ScanVibeState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ScanVibe',
          theme: ScanVibeTheme.light(),
          locale: state.locale,
          supportedLocales: ScanVibeLocalizations.supportedLocales,
          localizationsDelegates: const [
            ScanVibeLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: state.hasCompletedOnboarding
              ? HomeShell(state: state)
              : OnboardingLanguageScreen(state: state),
        );
      },
    );
  }
}

class ScanVibeState extends ChangeNotifier {
  ScanVibeState({
    required this._store,
    required this._ocrClient,
    ImageCaptureService? imageCaptureService,
    DocumentExporter? documentExporter,
    Uuid? uuid,
    this._locale = const Locale('en'),
    this._hasCompletedOnboarding = false,
    List<ScanDocument> documents = const [],
  }) : _imageCaptureService = imageCaptureService ?? ImageCaptureService(),
       _documentExporter = documentExporter ?? DocumentExporter(),
       _uuid = uuid ?? const Uuid(),
       _documents = List.of(documents);

  final AppStore _store;
  final OcrClient _ocrClient;
  final ImageCaptureService _imageCaptureService;
  final DocumentExporter _documentExporter;
  final Uuid _uuid;
  Locale _locale;
  bool _hasCompletedOnboarding;
  List<ScanDocument> _documents;
  bool _isBusy = false;
  String? _lastExportPath;
  String? _lastError;
  String? _captureError;
  bool? _isCameraAvailable;
  String _ocrLanguage = 'latin';

  static Future<ScanVibeState> load({
    required AppStore store,
    required OcrClient ocrClient,
  }) async {
    return ScanVibeState(
      store: store,
      ocrClient: ocrClient,
      locale: Locale(store.localeCode),
      hasCompletedOnboarding: store.hasCompletedOnboarding,
      documents: store.documents,
    );
  }

  Locale get locale => _locale;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  List<ScanDocument> get documents => List.unmodifiable(_documents);
  bool get isBusy => _isBusy;
  String? get lastExportPath => _lastExportPath;
  String? get lastError => _lastError;
  String? get captureError => _captureError;
  bool get isCameraAvailable => _isCameraAvailable ?? true;
  String get ocrLanguage => _ocrLanguage;

  void setOcrLanguage(String language) {
    _ocrLanguage = language;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _store.saveLocale(locale.languageCode);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _store.saveOnboardingComplete();
    notifyListeners();
  }

  Future<void> createDocumentFromCamera() async {
    try {
      _captureError = null;
      notifyListeners();
      await _captureDocument(ImageSourceKind.camera);
    } catch (e) {
      _handleCaptureError(e);
    }
  }

  Future<void> importDocumentFromGallery() async {
    try {
      _captureError = null;
      notifyListeners();
      await _captureDocument(ImageSourceKind.gallery);
    } catch (e) {
      _handleCaptureError(e);
    }
  }

  Future<void> addPage(String documentId, ImageSourceKind source) async {
    try {
      _captureError = null;
      notifyListeners();
      final image = await _imageCaptureService.pick(source);
      if (image == null) {
        return;
      }
      final index = _documents.indexWhere(
        (document) => document.id == documentId,
      );
      if (index == -1) {
        return;
      }
      final page = ScanPage(
        id: _uuid.v4(),
        imagePath: image.path,
        createdAt: DateTime.now(),
        ocrStatus: OcrStatus.queued,
      );
      _documents[index] = _documents[index].copyWith(
        pages: [..._documents[index].pages, page],
        updatedAt: DateTime.now(),
      );
      await _persistAndNotify();
      await processQueuedPages();
    } catch (e) {
      _handleCaptureError(e);
    }
  }

  void clearCaptureError() {
    _captureError = null;
    notifyListeners();
  }

  void _handleCaptureError(Object error) {
    if (error is PlatformException) {
      if (error.code == 'no_available_camera') {
        _isCameraAvailable = false;
        _captureError = 'noCameraError';
      } else if (error.code == 'camera_access_denied') {
        _captureError = 'cameraPermissionError';
      } else if (error.code == 'photo_access_denied') {
        _captureError = 'galleryPermissionError';
      } else {
        _captureError = 'unknownCaptureError';
      }
    } else {
      _captureError = 'unknownCaptureError';
    }
    notifyListeners();
  }

  Future<void> processQueuedPages({String languageHint = 'auto'}) async {
    if (_isBusy) {
      return;
    }
    _isBusy = true;
    _lastError = null;
    notifyListeners();

    final hint = languageHint == 'auto' ? _ocrLanguage : languageHint;

    try {
      for (final document in List<ScanDocument>.from(_documents)) {
        for (final page in document.pages.where(
          (page) => page.ocrStatus.canRun,
        )) {
          await _processPage(document.id, page.id, hint);
        }
      }
    } finally {
      _isBusy = false;
      await _persistAndNotify();
    }
  }

  Future<void> retryDocument(String documentId) async {
    final index = _documents.indexWhere(
      (document) => document.id == documentId,
    );
    if (index == -1) {
      return;
    }
    _documents[index] = _documents[index].copyWith(
      pages: [
        for (final page in _documents[index].pages)
          page.ocrStatus == OcrStatus.failed
              ? page.copyWith(ocrStatus: OcrStatus.queued)
              : page,
      ],
      updatedAt: DateTime.now(),
    );
    await _persistAndNotify();
    await processQueuedPages();
  }

  Future<void> exportDocument(String documentId) async {
    final document = _documents.firstWhere((item) => item.id == documentId);
    _lastExportPath = await _documentExporter.exportPdf(document);
    notifyListeners();
  }

  Future<void> deleteDocument(String documentId) async {
    _documents = _documents
        .where((document) => document.id != documentId)
        .toList();
    await _persistAndNotify();
  }

  Future<void> _captureDocument(ImageSourceKind source) async {
    final image = await _imageCaptureService.pick(source);
    if (image == null) {
      return;
    }
    final now = DateTime.now();
    final document = ScanDocument(
      id: _uuid.v4(),
      title: 'Scan ${_documents.length + 1}',
      createdAt: now,
      updatedAt: now,
      pages: [
        ScanPage(
          id: _uuid.v4(),
          imagePath: image.path,
          createdAt: now,
          ocrStatus: OcrStatus.queued,
        ),
      ],
    );
    _documents = [document, ..._documents];
    await _persistAndNotify();
    await processQueuedPages();
  }

  Future<void> _processPage(
    String documentId,
    String pageId,
    String languageHint,
  ) async {
    _replacePage(
      documentId,
      pageId,
      (page) => page.copyWith(ocrStatus: OcrStatus.processing),
    );
    notifyListeners();
    try {
      final page = _documents
          .firstWhere((document) => document.id == documentId)
          .pages
          .firstWhere((item) => item.id == pageId);
      final result = await _ocrClient.extractText(
        imagePath: page.imagePath,
        languageHint: languageHint,
      );
      _replacePage(
        documentId,
        pageId,
        (page) => page.copyWith(
          ocrStatus: OcrStatus.complete,
          extractedText: result.text,
          confidence: result.confidence,
          errorMessage: null,
        ),
      );
    } on OcrException catch (error) {
      _lastError = error.message;
      _replacePage(
        documentId,
        pageId,
        (page) => page.copyWith(
          ocrStatus: OcrStatus.failed,
          errorMessage: error.message,
        ),
      );
    }
    await _persistAndNotify();
  }

  void _replacePage(
    String documentId,
    String pageId,
    ScanPage Function(ScanPage page) update,
  ) {
    _documents = [
      for (final document in _documents)
        if (document.id == documentId)
          document.copyWith(
            updatedAt: DateTime.now(),
            pages: [
              for (final page in document.pages)
                page.id == pageId ? update(page) : page,
            ],
          )
        else
          document,
    ];
  }

  Future<void> _persistAndNotify() async {
    await _store.saveDocuments(_documents);
    notifyListeners();
  }
}
