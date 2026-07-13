# ScanVibe

ScanVibe is a Flutter document scanner that captures pages, recognizes text on
device, and exports searchable PDFs. It is designed to work locally without an
internet connection or OCR server.

## Current Capabilities

- First-run language selection and localized UI.
- Camera capture and gallery import.
- On-device OCR through Google ML Kit text recognition.
- Local document/page persistence with visible processing states.
- PDF export from captured page images and extracted text.
- Android and iOS camera/photo permission metadata.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d <device>
```

No backend service or API token is required.
