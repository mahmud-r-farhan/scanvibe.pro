import 'dart:convert';

enum OcrStatus {
  queued,
  processing,
  complete,
  failed;

  bool get canRun => this == OcrStatus.queued || this == OcrStatus.failed;
}

class ScanPage {
  const ScanPage({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.ocrStatus,
    this.extractedText = '',
    this.confidence,
    this.errorMessage,
  });

  final String id;
  final String imagePath;
  final DateTime createdAt;
  final OcrStatus ocrStatus;
  final String extractedText;
  final double? confidence;
  final String? errorMessage;

  ScanPage copyWith({
    OcrStatus? ocrStatus,
    String? extractedText,
    double? confidence,
    String? errorMessage,
  }) {
    return ScanPage(
      id: id,
      imagePath: imagePath,
      createdAt: createdAt,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      extractedText: extractedText ?? this.extractedText,
      confidence: confidence ?? this.confidence,
      errorMessage: errorMessage,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
    'ocrStatus': ocrStatus.name,
    'extractedText': extractedText,
    'confidence': confidence,
    'errorMessage': errorMessage,
  };

  factory ScanPage.fromJson(Map<String, Object?> json) {
    return ScanPage(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      ocrStatus: OcrStatus.values.byName(json['ocrStatus'] as String),
      extractedText: (json['extractedText'] as String?) ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class ScanDocument {
  const ScanDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScanPage> pages;

  String get combinedText {
    return pages
        .map((page) => page.extractedText)
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n');
  }

  bool get hasFailedPages =>
      pages.any((page) => page.ocrStatus == OcrStatus.failed);
  bool get hasQueuedPages =>
      pages.any((page) => page.ocrStatus == OcrStatus.queued);

  ScanDocument copyWith({DateTime? updatedAt, List<ScanPage>? pages}) {
    return ScanDocument(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pages: pages ?? this.pages,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pages': pages.map((page) => page.toJson()).toList(),
  };

  factory ScanDocument.fromJson(Map<String, Object?> json) {
    return ScanDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pages: [
        for (final page in json['pages'] as List<Object?>)
          ScanPage.fromJson(page as Map<String, Object?>),
      ],
    );
  }

  static List<ScanDocument> decodeList(String value) {
    final decoded = jsonDecode(value) as List<Object?>;
    return [
      for (final item in decoded)
        ScanDocument.fromJson(item as Map<String, Object?>),
    ];
  }

  static String encodeList(List<ScanDocument> documents) {
    return jsonEncode(documents.map((document) => document.toJson()).toList());
  }
}
