# AGENTS.md - ScanVibe Pro

Standing instructions for coding agents working in this repository.

## 1. Product Direction

ScanVibe is a cross-platform document scanner that works locally. Users capture
or import document pages, recognize text on device, and export polished PDFs.

Hard requirement: the app must not require internet connectivity, hosted OCR, API
tokens, or a Python backend for core scanning, OCR, document viewing, or export.

## 2. Architecture

```
[ Flutter App ]
     | capture / import page images
     v
[ On-device OCR ]
     | Google ML Kit text recognition
     v
[ Local Document Output ]
     | saved pages + extracted text + PDF export
```

### Flutter responsibilities

- Camera capture and gallery import.
- Local page/session management.
- On-device OCR through `google_mlkit_text_recognition`.
- Local persistence for document metadata and extracted text.
- PDF assembly using the `pdf` / `printing` packages.
- Localization, onboarding, settings, and all user-facing UI.

### Do not add

- Python OCR service.
- Hosted OCR endpoint.
- API-token requirements.
- Internet permission for OCR.
- Copy that says OCR needs a server, network, or upload.
- AdMob or ad-related UI.

## 3. Accurate Product Copy

App name: **ScanVibe: Offline OCR Scanner**

Short name: `ScanVibe`

Short description:

> Scan documents, extract text on device, and export clean searchable PDFs.

Required copy truth:

- It is acceptable to say the app works offline.
- It is acceptable to say OCR runs on device.
- Do not claim cloud sync, server backup, or hosted processing unless those
  features are later added intentionally.

## 4. Definition of Done

- `flutter analyze` passes with zero warnings.
- `flutter test` passes.
- Every new screen gets a widget test.
- Non-trivial business logic gets a unit test.
- User-facing strings go through localization.
- OCR failures show a visible state and a retry path.
- No document image or extracted text is logged or uploaded.
- Screens respect phone and tablet widths.

## 5. Localization

- Use the existing Flutter localization delegate in
  `lib/src/l10n/scanvibe_localizations.dart`.
- Default locale is English (`en`).
- The first onboarding screen must remain a language picker.
- Settings must keep an immediate language switcher.
- UI language and document language are independent; do not assume they match.

## 6. Commands

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d <device>
```
