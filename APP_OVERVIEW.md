# ScanVibe Pro — App Overview

**Version:** 2.0.0+1  
**Last Updated:** July 21, 2026  
**Developer:** Bengal Bytes  
**Platforms:** Android, iOS (Flutter)

---

## 1. Product Vision

ScanVibe Pro is a **privacy-first, fully offline document scanner**. Users capture or import document pages, extract text via on-device AI (OCR), organize items with folders and tags, and export polished searchable PDFs — **all without an internet connection**. No cloud upload, no API tokens, no account required.

### Core Value Proposition

> *"Scan documents, extract text on device, and export clean searchable PDFs — 100% offline."*

### Differentiators

| Factor | ScanVibe Pro | Competitors (Adobe Scan, Microsoft Lens) |
|---|---|---|
| **OCR location** | On-device (Google ML Kit) | Cloud upload required |
| **Database storage** | Local SQLite (Drift) | Cloud account / sync servers |
| **Internet needed** | No | Yes |
| **Account required** | No | Yes |
| **Data privacy** | Images/text stay on device | Uploaded to servers |
| **Cost / Ads** | Free / Pro | Freemium / subscription / ads |

---

## 2. Architecture

```
┌────────────────────────────────────────────────────────┐
│                      Flutter App                       │
│                                                        │
│  ┌────────────────┐   ┌────────────────┐   ┌─────────┐ │
│  │ UI Layer       │   │ Riverpod State │   │Services │ │
│  │ (Screens/      │◄──┤ (documents-    │◄──┤         │ │
│  │  Widgets)      │   │  Provider)     │   │• Camera │ │
│  └──────┬─────────┘   └───────┬────────┘   │• OCR    │ │
│         │                     │            │• Image  │ │
│         ▼                     ▼            └─────────┘ │
│  ┌────────────────┐   ┌────────────────┐               │
│  │ Routing        │   │ Database Layer │               │
│  │ (GoRouter)     │   │ (Drift SQLite) │               │
│  └────────────────┘   └────────────────┘               │
│                               │                        │
│                               ▼                        │
│                       ┌────────────────┐               │
│                       │ Google ML Kit  │               │
│                       │  (OCR Engine)  │               │
│                       └────────────────┘               │
└────────────────────────────────────────────────────────┘
```

### Data Flow (Scan → PDF)

```
User captures/imports image
        │
        ▼
CameraService / ImagePicker (camera/gallery)
        │
        ▼
ImageProcessingService
  → Formats image, adjusts HSL color channels (Image v4.x), applies filters
        │
        ▼
DocumentsNotifier (Riverpod)
  → Creates Document + ScanPage (OcrStatus.queued)
  → Inserts into SQLite database via Drift
  → Spawns background OCR processing
        │
        ▼
OCRService
  → Status → OcrStatus.processing (UI shows spinner)
  → ML Kit text recognition
  → Status → OcrStatus.complete / OcrStatus.failed
  → Stores extractedText + confidence in Drift database
        │
        ▼
PDF Generation (ExportScreen / ScanBatchScreen)
  → Pre-loads page images in memory (avoiding async builders)
  → Assembles PDF document (images + extracted text layer)
  → Saves to temporary directory
  → Shares via platform share sheet (Share package)
```

---

## 3. Feature Inventory

### ✔️ Implemented (v2.0.0)

| Feature | Details | User-Facing |
|---|---|---|
| **Camera capture** | Take photo of document, custom focus & zoom controls | Scan / Camera screens |
| **Gallery import** | Pick single or multiple images from photo library | Scan / Documents screens |
| **On-device OCR** | Google ML Kit text recognition, offline script support | Background (visible status) |
| **Advanced filters** | Color enhancement (Contrast/Lightness/Saturation) | Scan Review screen |
| **Multi-page documents** | Add, reorder, or delete pages dynamically | Detail + Batch screens |
| **Searchable PDF export** | Embedded OCR text layer in exported PDF | Export screen |
| **Folders & Tags** | Group documents in folders and tag them | Folders + Tags sheets |
| **Full-text search** | Instant search matching titles and extracted text | Documents screen |
| **RTL support** | Fully localized interface supporting Arabic | Universal |
| **Dark mode** | Material 3 theme switcher | Settings screen |

---

## 4. Tech Stack & Dependencies

### Runtime Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | UI framework |
| `flutter_riverpod` | ^2.6.1 | State management framework |
| `drift` / `drift_dev` | ^2.28.2 | Type-safe SQLite database builder |
| `sqlite3_flutter_libs` | ^0.5.42 | SQLite native bindings |
| `go_router` | ^14.8.1 | Declarative routing system |
| `shared_preferences` | ^2.5.5 | Settings / onboarding persistence |
| `google_mlkit_text_recognition`| ^0.16.0 | On-device OCR engine |
| `image` | ^4.9.1 | Image processing & HSL manipulation |
| `pdf` | ^3.13.0 | PDF document generation |
| `printing` | ^5.15.0 | Print utilities |
| `share_plus` | ^10.1.4 | Sharing files and text |
| `uuid` | ^4.5.3 | ID generation |

---

## 5. Codebase Structure

```
scanvibe_pro/
├── assets/
│   ├── logo.jpg              # App icon source
│   └── scanvibe.jpg          # Splash screen image
│
├── lib/
│   ├── main.dart             # Entry point
│   └── src/
│       ├── app.dart          # ScanVibeApp widget
│       ├── router.dart       # GoRouter path mappings
│       ├── enums.dart        # SortField, FilterType, ScanMode, etc.
│       │
│       ├── database/
│       │   └── app_database.dart       # Drift database, table structures
│       │
│       ├── l10n/
│       │   └── scanvibe_localizations.dart   # Custom translation maps
│       │
│       ├── providers/
│       │   ├── database_provider.dart  # Database provider
│       │   ├── documents_provider.dart # Document states & notifiers
│       │   └── settings_provider.dart  # User configurations provider
│       │
│       ├── services/
│       │   ├── camera_service.dart     # Camera configurations wrapper
│       │   ├── image_processing_service.dart # Color filters & rotations
│       │   └── ocr_service.dart        # ML Kit OCR client wrapper
│       │
│       └── ui/
│           ├── app_shell.dart          # Adaptive bottom nav & nav rail shell
│           ├── screens/
│           │   ├── onboarding/         # Onboarding language choices
│           │   ├── home/               # Dashboard stats
│           │   ├── scan/               # Batch scanning, camera, review
│           │   ├── documents/          # Document lists, folders, tags
│           │   ├── text/               # OCR text editor and viewer
│           │   └── settings/           # Configurations & about
│
└── test/
    ├── widget_test.dart             # Smoke test
    ├── document_health_test.dart    # DocumentsState test
    ├── image_capture_test.dart      # CameraService stub tests
    └── scan_screen_test.dart        # App initialization tests
```

---

## 6. Data Model (Drift Schema)

```
   ┌───────────────┐           ┌───────────────┐
   │    Folders    │1        * │   Documents   │
   │  - id (PK)    ├──────────►│  - id (PK)    │
   │  - name       │           │  - title      │
   │  - color      │           │  - folder_id  │
   └───────────────┘           └──────┬────────┘
                                      │ 1
                                      │
                                      │ *
                               ┌──────▼────────┐
                               │   ScanPages   │
                               │  - id (PK)    │
   ┌───────────────┐           │  - doc_id (FK)│
   │     Tags      │1          │  - img_path   │
   │  - id (PK)    ├─────┐     │  - ocr_status │
   │  - name       │     │     └───────────────┘
   └───────────────┘     │
                         │ *
                  ┌──────▼────────┐
                  │ DocumentTags  │ (Many-to-Many Joint Table)
                  │ - doc_id (FK) │
                  │ - tag_id (FK) │
                  └───────────────┘
```

---

## 7. Key Design Decisions

| Decision | Rationale |
|---|---|
| **Drift (SQLite)** | Replaced `SharedPreferences` JSON storage for relational integrity, transactional safety, and high-performance full-text search. |
| **Riverpod** | Solved cross-screen state sharing, lazy instantiation, and automatic state invalidation. |
| **GoRouter** | Implemented routing path configuration, deep linking, and cleaner programmatic navigation. |
| **Pre-loaded Memory Images** | Prevents asynchronous await statements inside PDF generation widgets (`pdf` package requires all widgets to compile synchronously). |

---

*Document maintained by Bengal Bytes. Last updated: July 21, 2026.*
