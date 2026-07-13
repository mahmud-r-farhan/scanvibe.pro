import 'package:flutter_test/flutter_test.dart';
import 'package:scanvibe_pro/src/models/document_health.dart';
import 'package:scanvibe_pro/src/models/scan_document.dart';

void main() {
  test('calculates document OCR progress and attention state', () {
    final now = DateTime(2026, 7, 10);
    final document = ScanDocument(
      id: 'document',
      title: 'Scan',
      createdAt: now,
      updatedAt: now,
      pages: [
        ScanPage(
          id: 'one',
          imagePath: '/tmp/one.jpg',
          createdAt: now,
          ocrStatus: OcrStatus.complete,
          extractedText: 'Done',
        ),
        ScanPage(
          id: 'two',
          imagePath: '/tmp/two.jpg',
          createdAt: now,
          ocrStatus: OcrStatus.queued,
        ),
        ScanPage(
          id: 'three',
          imagePath: '/tmp/three.jpg',
          createdAt: now,
          ocrStatus: OcrStatus.failed,
        ),
      ],
    );

    final health = calculateDocumentHealth(document);

    expect(health.totalPages, 3);
    expect(health.completePages, 1);
    expect(health.queuedPages, 1);
    expect(health.failedPages, 1);
    expect(health.completionRatio, closeTo(1 / 3, 0.001));
    expect(health.needsAttention, isTrue);
  });
}
