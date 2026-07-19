enum ScanMode {
  document('Document', 'Auto edge detection & perspective correction'),
  idCard('ID Card', 'Fixed ratio cropping for IDs & passports'),
  whiteboard('Whiteboard', 'Shadow & stain removal for whiteboards'),
  qrCode('QR Code', 'Instant QR/barcode decode'),
  book('Book', 'De-warp & flatten curved pages'),
  receipt('Receipt', 'Thermal paper cleanup & enhancement');

  const ScanMode(this.displayName, this.description);
  final String displayName;
  final String description;
}

enum FilterType {
  autoEnhance('Auto Enhance', 'Adaptive histogram equalization'),
  blackWhite('Black & White', 'Adaptive thresholding for text'),
  grayscale('Grayscale', 'Desaturation with contrast boost'),
  magicColor('Magic Color', 'Saturation & edge enhancement'),
  sharpen('Sharpen', 'Unsharp mask for blurry captures'),
  clean('Clean', 'Morphological cleanup for stains');

  const FilterType(this.displayName, this.description);
  final String displayName;
  final String description;
}

enum OcrStatus {
  queued,
  processing,
  complete,
  failed;

  bool get canRun => this == OcrStatus.queued || this == OcrStatus.failed;
}

enum ExportFormat {
  pdf('PDF', '.pdf'),
  jpeg('JPEG', '.jpg'),
  txt('Text', '.txt');

  const ExportFormat(this.displayName, this.extension);
  final String displayName;
  final String extension;
}

enum SortField {
  dateUpdated,
  dateCreated,
  name,
  pageCount;

  String get displayName => switch (this) {
        SortField.dateUpdated => 'Last Modified',
        SortField.dateCreated => 'Date Created',
        SortField.name => 'Name',
        SortField.pageCount => 'Page Count',
      };
}

enum SortOrder { ascending, descending }

enum DocumentViewMode { grid, list }

enum ScanLanguage {
  latin('Latin', 'en'),
  devanagari('Devanagari', 'hi'),
  chinese('Chinese', 'zh'),
  japanese('Japanese', 'ja'),
  korean('Korean', 'ko');

  const ScanLanguage(this.displayName, this.code);
  final String displayName;
  final String code;
}
