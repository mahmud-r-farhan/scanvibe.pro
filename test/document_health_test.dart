// document_health_test.dart
//
// Tests the DocumentsState computed properties (totalDocuments, totalPages,
// pendingPages) that replace the old DocumentHealth helper which no longer
// exists in the Riverpod+Drift architecture.

import 'package:flutter_test/flutter_test.dart';
import 'package:scanvibe_pro/src/providers/documents_provider.dart';



void main() {
  group('DocumentsState computed properties', () {
    test('empty state has zero totals', () {
      const state = DocumentsState();
      expect(state.totalDocuments, 0);
      expect(state.totalPages, 0);
      expect(state.pendingPages, 0);
    });

    test('searchQuery defaults to empty string', () {
      const state = DocumentsState();
      expect(state.searchQuery, '');
    });

    test('isProcessing defaults to false', () {
      const state = DocumentsState();
      expect(state.isProcessing, isFalse);
    });

    test('copyWith preserves existing values when not overridden', () {
      const original = DocumentsState(searchQuery: 'hello', isProcessing: true);
      final copy = original.copyWith();
      expect(copy.searchQuery, 'hello');
      expect(copy.isProcessing, isTrue);
    });

    test('copyWith overrides individual fields', () {
      const original = DocumentsState(searchQuery: 'old');
      final updated = original.copyWith(searchQuery: 'new');
      expect(updated.searchQuery, 'new');
    });
  });
}
