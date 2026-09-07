import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanvibe_pro/src/providers/settings_provider.dart';
import 'package:scanvibe_pro/src/providers/documents_provider.dart';
import 'package:scanvibe_pro/src/database/app_database.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsState Pro & Watermark features', () {
    test('defaults to isPro false and watermark true', () {
      const state = SettingsState();
      expect(state.isPro, isFalse);
      expect(state.pdfWatermark, isTrue);
      // Free users always include watermark
      expect(state.shouldIncludeWatermark, isTrue);
    });

    test('pro users can disable watermark', () {
      const proWithWatermark = SettingsState(isPro: true, pdfWatermark: true);
      expect(proWithWatermark.shouldIncludeWatermark, isTrue);

      const proClean = SettingsState(isPro: true, pdfWatermark: false);
      expect(proClean.shouldIncludeWatermark, isFalse);
    });

    test('free users cannot disable watermark even if pdfWatermark is false', () {
      const freeAttempt = SettingsState(isPro: false, pdfWatermark: false);
      expect(freeAttempt.shouldIncludeWatermark, isTrue);
    });

    test('copyWith updates isPro and pdfWatermark properly', () {
      const original = SettingsState();
      final updated = original.copyWith(isPro: true, pdfWatermark: false);
      expect(updated.isPro, isTrue);
      expect(updated.pdfWatermark, isFalse);
      expect(updated.shouldIncludeWatermark, isFalse);
    });
  });

  group('DocumentsState getDocumentById safe lookup', () {
    test('returns null when document does not exist', () {
      const state = DocumentsState();
      expect(state.getDocumentById('non_existent_id'), isNull);
    });

    test('returns matching document when present', () {
      final now = DateTime.now();
      final sampleDoc = DocumentWithPages(
        document: Document(
          id: 'doc-123',
          title: 'Tax Receipt',
          createdAt: now,
          updatedAt: now,
          isFavorite: false,
          scanMode: 'document',
        ),
        pages: const [],
      );

      final state = DocumentsState(documents: [sampleDoc]);
      final found = state.getDocumentById('doc-123');
      expect(found, isNotNull);
      expect(found!.document.title, 'Tax Receipt');
      expect(state.getDocumentById('doc-999'), isNull);
    });
  });
}
