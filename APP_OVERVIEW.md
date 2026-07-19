# ScanVibe Pro — App Overview

**Version:** 1.0.0+1  
**Last Updated:** July 13, 2026  
**Developer:** Bengal Bytes  
**Platforms:** Android, iOS (Flutter)

---

## 1. Product Vision

ScanVibe is a **privacy-first, fully offline document scanner**. Users capture or import document pages, extract text via on-device AI (OCR), and export polished searchable PDFs — **all without an internet connection**. No cloud upload, no API tokens, no account required.

### Core Value Proposition

> *"Scan documents, extract text on device, and export clean searchable PDFs — no internet."*

### Differentiators

| Factor | ScanVibe | Competitors (Adobe Scan, Microsoft Lens) |
|---|---|---|
| **OCR location** | On-device (Google ML Kit) | Cloud upload required |
| **Internet needed** | No | Yes |
| **Account required** | No | Yes |
| **Data privacy** | Images/text stay on device | Uploaded to servers |
| **Cost** | Free | Freemium / subscription |

---

## 2. Architecture

```
┌──────────────────────────────────────────────────┐
│                  Flutter App                      │
│                                                    │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ UI Layer    │  │ ScanVibeState │  │ Services  │ │
│  │ (Screens/   │◄─┤ (ChangeNtf.) │◄─┤           │ │
│  │  Widgets)   │  │              │  │ • AppStore│ │
│  └─────────────┘  │ • documents  │  │ • OcrClnt │ │
│                   │ • locale     │  │ • ImgCapt │ │
│                   │ • darkMode   │  │ • DocExp  │ │
│  ┌─────────────┐  │ • searchQ    │  └───────────┘ │
│  │ Models      │  │ • isBusy     │       │        │
│  │ • ScanDoc   │  └──────────────┘       │        │
│  │ • ScanPage  │         │               ▼        │
│  │ • DocHealth │         │        ┌───────────┐   │
│  └─────────────┘         │        │ SharedPref│   │
│                          │        │ (Persist) │   │
│                          ▼        └───────────┘   │
│                   ┌──────────────┐                │
│                   │ Google ML Kit│                │
│                   │ (OCR Engine) │                │
│                   └──────────────┘                │
└──────────────────────────────────────────────────┘
```

### Data Flow (Scan → PDF)

```
User captures/imports image
        │
        ▼
ImageCaptureService (camera/gallery)
        │
        ▼
ScanVibeState._captureDocument()
  → Creates ScanDocument + ScanPage (OcrStatus.queued)
  → Persists to SharedPreferences via AppStore
  → Triggers processQueuedPages()
        │
        ▼
processQueuedPages()
  → Collects all runnable pages (queued/failed)
  → Batches into groups of 3 for concurrent processing
  → For each page:
      1. Status → OcrStatus.processing (UI shows spinner)
      2. OcrClient.extractText() → Google ML Kit
      3. Status → OcrStatus.complete / OcrStatus.failed
      4. Stores extractedText + confidence
      5. Persists after each page
        │
        ▼
DocumentExporter.exportPdf()
  → Reads page images from disk
  → Assembles PDF with images + extracted text
  → Saves to app documents directory
  → Shares via platform share sheet (printing package)
```

---

## 3. Feature Inventory

### ✔️ Implemented (v1.0.0)

| Feature | Details | User-Facing |
|---|---|---|
| **Camera capture** | Take photo of document, auto-queues for OCR | Scan / Documents screens |
| **Gallery import** | Pick image from photo library | Scan / Documents screens |
| **On-device OCR** | Google ML Kit text recognition, 6 script options | Background (visible progress) |
| **Multi-page documents** | Add pages to any document anytime | Detail screen + Documents actions |
| **Searchable PDF export** | Embedded OCR text in PDF | Documents / Detail screens |
| **Document list** | Sorted by recency, status chips, progress bars | Documents screen (main tab) |
| **Document search** | Real-time filter by title or text content | Documents screen search bar |
| **Document detail** | Full page previews, extracted text viewer | Tap any document card |
| **Rename documents** | Inline title editing in detail screen AppBar | Detail screen |
| **Delete documents** | Swipe-to-delete with confirmation dialog | Documents + Detail screens |
| **Retry failed OCR** | One-tap retry for failed pages | Documents / Detail screens |
| **Copy extracted text** | Copy to clipboard | Documents / Detail screens |
| **Pull-to-refresh** | Refresh document list / trigger OCR | Documents screen |
| **Dark mode** | Full Material 3 dark theme, persistent | Settings toggle |
| **Language selection** | 6 languages, on first launch + settings | Onboarding + Settings |
| **Localized UI** | English, Spanish, Bengali, French, German, Arabic | All screens |
| **Responsive layout** | Bottom nav on phone, nav rail on tablet (≥720px) | Adaptive |
| **Concurrent OCR** | Up to 3 pages processed simultaneously | Background |
| **Error states** | Camera unavailable, permissions denied, OCR failures | Scan / Documents screens |
| **Empty states** | Onboarding language picker, no documents | First launch |

### 🗺️ Planned / Backlog

| Feature | Priority | Notes |
|---|---|---|
| Proactive camera check at startup | Low | `ImagePicker().isCameraAvailable()` |
| Snackbar feedback for add-page / OCR | Low | Localization keys already exist |
| Document page reordering | Medium | Drag-to-reorder in detail screen |
| Image editing (crop, rotate, filter) | Medium | Enhance scan quality |
| Folder/tag organization | Medium | For large document collections |
| Batch export multiple PDFs | Low | Zip or multi-export |
| Backup & restore documents | Medium | Export/import document JSON |
| Edge-to-edge on Android | Low | Flutter 3.x support |

---

## 4. Tech Stack & Dependencies

### Runtime Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `flutter_localizations` | SDK | i18n infrastructure |
| `intl` | 0.20.2 | Date formatting, locale support |
| `shared_preferences` | ^2.5.5 | Key-value persistence (settings + documents) |
| `uuid` | ^4.5.3 | Unique document/page IDs |
| `collection` | ^1.19.1 | Collection utilities |
| `image_picker` | ^1.2.3 | Camera capture + gallery import |
| `path_provider` | ^2.1.6 | File system paths for PDF export |
| `pdf` | ^3.13.0 | PDF document generation |
| `printing` | ^5.15.0 | PDF sharing via platform share sheet |
| `google_mlkit_text_recognition` | ^0.16.0 | On-device OCR engine |
| `url_launcher` | ^6.3.1 | Open Play Store links |

### Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_test` | SDK | Widget/unit testing |
| `flutter_launcher_icons` | ^0.14.3 | App icon generation |
| `flutter_native_splash` | ^2.4.4 | Native splash screen |
| `flutter_lints` | ^6.0.0 | Dart lint rules |

### SDK Constraints

- **Dart SDK:** `^3.12.2`
- **Google ML Kit:** Requires physical device (not emulator) for OCR
- **Minimum Android:** API 21+ (ML Kit requirement)
- **Minimum iOS:** 12.0+ (ML Kit requirement)

---

## 5. Codebase Structure

```
scanvibe_pro/
├── assets/
│   ├── logo.jpg              # App icon source
│   └── scanvibe.jpg          # Splash screen image
│
├── lib/
│   ├── main.dart             # Entry point, service initialization
│   └── src/
│       ├── app.dart          # ScanVibeApp widget + ScanVibeState (central state)
│       │
│       ├── l10n/
│       │   └── scanvibe_localizations.dart   # 6-language translation map
│       │
│       ├── models/
│       │   ├── scan_document.dart    # ScanDocument, ScanPage, OcrStatus
│       │   └── document_health.dart  # DocumentHealth, calculateDocumentHealth()
│       │
│       ├── services/
│       │   ├── app_store.dart              # SharedPreferences persistence
│       │   ├── document_exporter.dart      # PDF generation
│       │   ├── image_capture_service.dart  # Camera/gallery abstraction
│       │   └── ocr_client.dart             # ML Kit text recognition
│       │
│       ├── theme/
│       │   └── scanvibe_theme.dart    # Light + Dark Material 3 themes
│       │
│       └── ui/
│           ├── home_shell.dart                  # Navigation shell (bottom nav / nav rail)
│           ├── onboarding_language_screen.dart   # First-run language picker
│           ├── screens/
│           │   ├── scan_screen.dart             # Create new scan
│           │   ├── documents_screen.dart         # Document list + search
│           │   ├── document_detail_screen.dart   # Page viewer, text, rename
│           │   └── settings_screen.dart          # Language, dark mode, info
│           └── widgets/
│               └── language_picker.dart   # Reusable language chip selector
│
├── test/
│   ├── widget_test.dart             # Onboarding + workspace smoke test
│   ├── document_health_test.dart    # DocumentHealth calculation
│   ├── image_capture_test.dart      # Capture + error handling
│   └── scan_screen_test.dart        # Scan screen UI + error banner
│
├── android/                    # Android platform config
├── ios/                        # iOS platform config
│
├── pubspec.yaml                # Dependencies, icons, splash config
├── analysis_options.yaml       # Dart lint configuration
├── APP_OVERVIEW.md             # ← This document
├── README.md                   # Quick-start guide
├── scanvibe-pro-AGENTS.md      # AI agent instructions (internal)
├── aso.md                      # App Store Optimization strategy
├── aso_descriptions.md         # Store listing copy
├── privacy_policy.html         # Privacy policy (web-viewable)
└── .gitignore
```

### Key Classes

| Class | Type | Responsibility |
|---|---|---|
| `ScanVibeState` | `ChangeNotifier` | Central application state & business logic |
| `ScanDocument` | Model | Document with title, dates, pages list |
| `ScanPage` | Model | Individual page with image, OCR status, text |
| `OcrStatus` | Enum | `queued → processing → complete / failed` |
| `DocumentHealth` | Model | Aggregated OCR progress calculation |
| `AppStore` | Service | Persistence layer via `SharedPreferences` |
| `OcrClient` | Abstract | OCR interface |
| `LocalOcrClient` | Impl | Google ML Kit text recognition |
| `ImageCaptureService` | Service | Camera/gallery image picking |
| `DocumentExporter` | Service | PDF generation with `pdf` + `printing` |

---

## 6. Data Model

### ScanDocument JSON Schema

```json
{
  "id": "uuid-string",
  "title": "Scan 3",
  "createdAt": "2026-07-13T10:30:00.000Z",
  "updatedAt": "2026-07-13T10:35:00.000Z",
  "pages": [
    {
      "id": "uuid-string",
      "imagePath": "/path/to/image.jpg",
      "createdAt": "2026-07-13T10:30:00.000Z",
      "ocrStatus": "complete",
      "extractedText": "Recognized text content...",
      "confidence": 0.94,
      "errorMessage": null
    }
  ]
}
```

### Storage Strategy

| Data | Storage | Key |
|---|---|---|
| **Documents list** | `SharedPreferences` (JSON string) | `scanvibe.documents` |
| **Locale preference** | `SharedPreferences` (string) | `scanvibe.locale` |
| **Onboarding status** | `SharedPreferences` (bool) | `scanvibe.onboarding_complete` |
| **Dark mode** | `SharedPreferences` (bool) | `scanvibe.dark_mode` |
| **Page images** | Device filesystem (picked/captured) | Image path stored in model |

> **Note:** `SharedPreferences` stores the entire document list as a serialized JSON string. This is adequate for dozens of documents but becomes a concern at hundreds+. Future migration to a local database (e.g., `drift`, `objectbox`, `isar`) is recommended for scale.

### OcrStatus State Machine

```
         ┌──────────┐
    ┌────►  Queued   ◄────┐
    │    └─────┬────┘     │
    │          │          │
    │    ┌─────▼────┐     │
    │    │Processing│     │
    │    └─────┬────┘     │
    │          │          │
    │    ┌─────▼────┐     │
    ├────┤ Complete │     │
    │    └──────────┘     │
    │    ┌──────────┐     │
    └────┤  Failed  ├─────┘ (retry)
         └──────────┘
```

---

## 7. UI / UX Flows

### Navigation Structure

```
                    ┌───────────────────┐
                    │  First Launch?    │
                    │         │         │
                    │    ┌────▼────┐    │
                    │    │Language │    │
                    │    │ Onboard │    │
                    │    └────┬────┘    │
                    │         │         │
                    │    ┌────▼────┐    │
                    │    │  Home   │    │
                    │    │ Shell   │    │
                    │    └────┬────┘    │
                    └───────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
        ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐
        │ Documents  │  │   Scan    │  │ Settings  │
        │ (default)  │  │           │  │           │
        └─────┬─────┘  └───────────┘  └───────────┘
              │
        ┌─────▼─────┐
        │ Document  │
        │ Detail    │
        └───────────┘
```

### Screen-by-Screen

#### Documents Screen (Tab 1)
- **Empty state:** Icon + message + Camera/Gallery buttons
- **Search:** AppBar toggle → real-time title/text filter
- **List:** Cards with page preview, title, page count, date, status chip, progress bar
- **Actions per card:** Add page, Export/Retry PDF, Copy text
- **Swipe:** Swipe left to delete (with confirmation)
- **Pull:** Pull down to trigger OCR processing
- **Tap:** Opens Document Detail screen

#### Scan Screen (Tab 2)
- **Header:** "Create New Document"
- **Scanner animation:** Animated viewport with laser line + corner brackets
- **OCR Language:** Dropdown (Latin, Devanagari, Chinese, Japanese, Korean)
- **Stats card:** Document count, page count, pending pages
- **Action buttons:** Camera, Gallery, Recognize pending
- **Error states:** Camera unavailable warning, permission errors

#### Document Detail Screen
- **Header:** Document title (tap to rename inline) + delete button
- **Stats bar:** Page count, text length, OCR confidence
- **Pages:** Horizontal scrollable page previews with status indicators + Add Page button
- **Text section:** Selectable extracted text with copy button
- **Bottom bar:** Export PDF / Retry button

#### Settings Screen (Tab 3)
- **Language:** Chip selector with 6 languages
- **Appearance:** Dark mode toggle (instant switch)
- **Privacy info:** Data stays on device
- **Network info:** Local OCR, works offline
- **More apps:** Link to Bengal Bytes Play Store
- **App info:** Version number

---

## 8. Localization

### Supported Locales

| Code | Language | RTL |
|---|---|---|
| `en` | English | No |
| `es` | Spanish | No |
| `bn` | Bengali | No |
| `fr` | French | No |
| `de` | German | No |
| `ar` | Arabic | Yes |

### Architecture

- **Custom `LocalizationsDelegate`** (no ARB files)
- Translation map: `Map<String, Map<String, String>>` with all keys per locale
- Fallback: English (`_values['en']`) for missing translations
- **~80 translation keys** per language
- UI language and OCR language are **independent**

### Key Categories

| Category | Keys |
|---|---|
| General app | `appName`, `continueAction`, `copyright` |
| Navigation | `documents`, `scan`, `settings` |
| Scanning | `camera`, `gallery`, `processQueue`, OCR language names |
| Document list | `emptyTitle`, `emptyBody`, `queued`, `processing`, `complete`, `failed` |
| Actions | `addPage`, `retry`, `exportPdf`, `delete`, `copyText`, `rename` |
| Detail | `documentDetail`, `pagesLabel`, `textPreview`, `ocrConfidence`, `noText` |
| Settings | `language`, `appearance`, `darkMode`, `lightMode`, `version`, `appInfo` |
| Errors | `noCameraError`, `cameraPermissionError`, `galleryPermissionError` |
| Snackbars | `textCopied`, `textExported`, `documentDeleted`, `titleUpdated` |
| Search | `searchDocuments`, `noSearchResults`, `emptySearchBody` |

---

## 9. Performance Considerations

### Current State

| Area | Assessment | Notes |
|---|---|---|
| OCR speed | ~1-5s per page | Depends on image size, device, script |
| Concurrent OCR | 3 pages parallel | Reduces total time for multi-page docs |
| UI rebuilds | Full on every `notifyListeners()` | Acceptable for current scale |
| Persistence | JSON string in SharedPreferences | OK for <100 documents |
| Image storage | Original images on filesystem | ~2-5 MB per photo |

### Optimization Opportunities

1. **Reduce UI rebuilds:** Batch `notifyListeners()` calls during concurrent OCR batches instead of after each page
2. **Image compression:** Apply lossy compression before storage (currently 92% quality, 2200px max width)
3. **Lazy loading:** Only load images for visible document cards
4. **Database migration:** Move from `SharedPreferences` JSON to `drift`/`isar` for document storage at scale
5. **OCR cache:** Skip re-OCR for already-complete pages on process-all

---

## 10. Development Workflow

### Prerequisites

```bash
# Install Flutter (see docs.flutter.dev)
flutter doctor  # Verify all checkboxes green

# Get dependencies
cd scanvibe_pro
flutter pub get
```

### Commands

```bash
# Analyze code
flutter analyze

# Run all tests
flutter test

# Format code
dart format lib test

# Run on device/emulator
flutter run -d <device_id>

# Build release
flutter build apk --split-per-abi     # Android
flutter build ios                      # iOS (requires macOS + Xcode)
```

### Definition of Done

- `flutter analyze` passes with **zero warnings**
- `flutter test` passes
- Every new screen has a widget test
- Non-trivial business logic has a unit test
- User-facing strings go through localization
- OCR failures show a visible state and a retry path
- No document image or extracted text is logged or uploaded
- Screens respect phone and tablet widths

---

## 11. Deployment Checklist

### Pre-Release

- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all pass
- [ ] Version bump in `pubspec.yaml`
- [ ] App icon generated (`flutter pub run flutter_launcher_icons`)
- [ ] Native splash screen generated (`flutter pub run flutter_native_splash:create`)
- [ ] Privacy policy linked in app store listing
- [ ] ASO keywords reviewed in `aso_descriptions.md`
- [ ] Test on physical device (camera, OCR, PDF export)
- [ ] Test offline mode (airplane mode)
- [ ] Test RTL layout (Arabic locale)

### Android Release

```bash
# Generate keystore (if first time)
keytool -genkey -v -keystore upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000

# Build release APK / App Bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
# Upload to Google Play Console
```

### iOS Release

```bash
# Build archive (requires Xcode on macOS)
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace
# Product → Archive → Upload to App Store Connect
```

---

## 12. Dependencies Graph

```
                    ┌─────────────┐
                    │   Flutter   │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    ┌────▼────┐      ┌────▼────┐      ┌─────▼─────┐
    │Material │      │flutter_ │      │ shared_    │
    │   UI    │      │localiztn│      │preferences │
    └─────────┘      └─────────┘      └───────────┘
         │
    ┌────┴──────────────────────────────┐
    │                                   │
    ▼                                   ▼
┌──────────┐                    ┌──────────────┐
│ image_   │                    │ google_mlkit │
│ picker   │                    │ text_recog.  │
└──────────┘                    └──────────────┘
    │                                   │
    ▼                                   ▼
┌──────────┐                    ┌──────────────┐
│path_prov.│                    │    pdf +     │
│          │                    │  printing    │
└──────────┘                    └──────────────┘
```

---

## 13. Key Design Decisions

| Decision | Rationale | Trade-off |
|---|---|---|
| **ChangeNotifier** over Riverpod/BLoC | Minimal dependencies, sufficient for current complexity | God class at scale; plan extraction |
| **SharedPreferences** for document storage | Simple, built-in, zero setup | Not scalable beyond ~100 documents |
| **Custom localization** over ARB files | Full control, no code generation | Harder to share with translators |
| **Batch concurrent OCR** (3 at a time) | Parallel speedup without overwhelming device | Slightly more complex error tracking |
| **Single-page navigation** (no GoRouter) | App is small (4 screens total) | Would need routing for deep links |
| **Private widgets** in screen files | Co-location with usage, easy to find | Not reusable across screens |
| **Material 3** | Modern design, adaptive by default | Slightly larger APK |

---

## 14. Troubleshooting

### Common Issues

| Symptom | Cause | Fix |
|---|---|---|
| `MissingPluginException` | Platform channel not initialized | Ensure `WidgetsFlutterBinding.ensureInitialized()` in `main()` |
| OCR returns empty text | Image too small, blurry, or unsupported script | Increase image quality, select correct OCR language |
| Camera unavailable on emulator | No physical camera | Use gallery import or test on physical device |
| `PlatformException(camera_access_denied)` | Permission not granted | User must grant in OS settings |
| PDF export fails | Image file deleted or path invalid | Document references non-existent file; re-capture |
| `SharedPreferences` load slow | Very large document JSON (>1MB) | Consider database migration |

### Debug Tips

```bash
# Check current SharedPreferences values (adb shell)
adb shell run-as com.bengalbytes.scanvibe \
  cat /data/data/com.bengalbytes.scanvibe/shared_prefs/FlutterSharedPreferences.xml

# View app logs
flutter logs

# Profile performance
flutter run --profile
```

---

*Document maintained by Bengal Bytes. Last updated: July 13, 2026.*
