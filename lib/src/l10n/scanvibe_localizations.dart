import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class ScanVibeLocalizations {
  ScanVibeLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('bn'),
    Locale('fr'),
    Locale('de'),
    Locale('ar'),
  ];
  static const delegate = _ScanVibeLocalizationsDelegate();

  static ScanVibeLocalizations of(BuildContext context) {
    return Localizations.of<ScanVibeLocalizations>(
      context,
      ScanVibeLocalizations,
    )!;
  }

  static final _values = <String, Map<String, String>>{
    'en': {
      'appName': 'ScanVibe',
      'languageTitle': 'Choose your language',
      'languageSubtitle': 'You can change this anytime in Settings.',
      'english': 'English',
      'spanish': 'Spanish',
      'bengali': 'Bengali',
      'french': 'French',
      'german': 'German',
      'arabic': 'Arabic',
      'continueAction': 'Continue',
      'documents': 'Documents',
      'scan': 'Scan',
      'settings': 'Settings',
      'newScan': 'New scan',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'processQueue': 'Recognize pending pages',
      'emptyTitle': 'No documents yet',
      'emptyBody':
          'Capture a page or import an image to start a searchable PDF.',
      'queued': 'Ready',
      'processing': 'Processing',
      'complete': 'Complete',
      'failed': 'Failed',
      'pages': 'pages',
      'page': 'page',
      'ocrQueueNote':
          'Text recognition runs on this device. No internet or server is required.',
      'retry': 'Retry',
      'exportPdf': 'Export PDF',
      'delete': 'Delete',
      'language': 'Language',
      'privacyTitle': 'Privacy',
      'privacyBody':
          'Images and extracted text stay on this device unless you export or share them.',
      'networkTitle': 'Local OCR',
      'networkBody':
          'Capture, text recognition, saved documents, and PDF export work offline.',
      'exported': 'PDF exported',
      'sampleText': 'Extracted text appears here after OCR.',
      'addPage': 'Add page',
      'autoLanguage': 'Auto detect',
      'lastError': 'Last issue',
      'noCameraError': 'No camera available on this device.',
      'cameraPermissionError':
          'Camera permission denied. Please grant access in settings.',
      'galleryPermissionError':
          'Gallery permission denied. Please grant access in settings.',
      'unknownCaptureError': 'Failed to capture or import image.',
      'dismiss': 'Dismiss',
      'cameraUnavailableHelp':
          'Camera is unavailable. Try importing from your gallery instead.',
      'pendingPages': 'pending pages',
      'pendingPage': 'pending page',
      'textCopied': 'Text copied to clipboard.',
      'copyText': 'Copy Text',
      'scanHeaderTitle': 'Create New Document',
      'scanHeaderSubtitle': 'Choose a source to scan and extract text.',
      'moreAppsTitle': 'More apps from Bengal Bytes',
      'moreAppsSubtitle':
          'Check out our other offline productivity tools on the Play Store.',
      'copyright': 'Copyright © Bengal Bytes',
      'ocrLanguageSelect': 'Recognition Language',
      'ocrLangLatin': 'Latin (English, Spanish, etc.)',
      'ocrLangBengali': 'Bengali (বাংলা)',
      'ocrLangDevanagari': 'Devanagari (Hindi, etc.)',
      'ocrLangChinese': 'Chinese (中文)',
      'ocrLangJapanese': 'Japanese (日本語)',
      'ocrLangKorean': 'Korean (한국어)',
      'ocrLangCyrillic': 'Cyrillic (Russian, etc.)',
    },
    'es': {
      'appName': 'ScanVibe',
      'languageTitle': 'Elige tu idioma',
      'languageSubtitle': 'Puedes cambiarlo en Ajustes.',
      'english': 'Inglés',
      'spanish': 'Español',
      'bengali': 'Bengalí',
      'french': 'Francés',
      'german': 'Alemán',
      'arabic': 'Árabe',
      'continueAction': 'Continuar',
      'documents': 'Documentos',
      'scan': 'Escanear',
      'settings': 'Ajustes',
      'newScan': 'Nuevo escaneo',
      'camera': 'Cámara',
      'gallery': 'Galería',
      'processQueue': 'Reconocer páginas pendientes',
      'emptyTitle': 'No hay documentos',
      'emptyBody': 'Captura una página o importa una imagen para empezar.',
      'queued': 'Listo',
      'processing': 'Procesando',
      'complete': 'Listo',
      'failed': 'Error',
      'pages': 'páginas',
      'page': 'página',
      'ocrQueueNote':
          'El reconocimiento de texto ocurre en este dispositivo, sin internet ni servidor.',
      'retry': 'Reintentar',
      'exportPdf': 'Exportar PDF',
      'delete': 'Eliminar',
      'language': 'Idioma',
      'privacyTitle': 'Privacidad',
      'privacyBody':
          'Las imágenes y el texto extraído permanecen en este dispositivo.',
      'networkTitle': 'OCR local',
      'networkBody':
          'Captura, reconocimiento, documentos guardados y PDF funcionan sin conexión.',
      'exported': 'PDF exportado',
      'sampleText': 'El texto extraído aparece aquí después del OCR.',
      'addPage': 'Agregar página',
      'autoLanguage': 'Detectar',
      'lastError': 'Último problema',
      'noCameraError': 'No hay cámara disponible en este dispositivo.',
      'cameraPermissionError':
          'Acceso a la cámara denegado. Habilítelo en Ajustes.',
      'galleryPermissionError':
          'Acceso a la galería denegado. Habilítelo en Ajustes.',
      'unknownCaptureError': 'Error al seleccionar o capturar la imagen.',
      'dismiss': 'Cerrar',
      'cameraUnavailableHelp':
          'La cámara no está disponible. Importe desde la galería.',
      'pendingPages': 'páginas pendientes',
      'pendingPage': 'página pendiente',
      'textCopied': 'Texto copiado al portapapeles.',
      'copyText': 'Copiar texto',
      'scanHeaderTitle': 'Crear nuevo documento',
      'scanHeaderSubtitle': 'Elija una fuente para escanear y extraer texto.',
      'moreAppsTitle': 'Más aplicaciones de Bengal Bytes',
      'moreAppsSubtitle':
          'Vea nuestras otras herramientas de productividad sin conexión en Play Store.',
      'copyright': 'Copyright © Bengal Bytes',
      'ocrLanguageSelect': 'Idioma de reconocimiento',
      'ocrLangLatin': 'Latín (inglés, español, etc.)',
      'ocrLangBengali': 'Bengalí (বাংলা)',
      'ocrLangDevanagari': 'Devanagari (hindi, etc.)',
      'ocrLangChinese': 'Chino (中文)',
      'ocrLangJapanese': 'Japonés (日本語)',
      'ocrLangKorean': 'Coreano (한국어)',
      'ocrLangCyrillic': 'Cirílico (ruso, etc.)',
    },
    'bn': {
      'appName': 'ScanVibe',
      'languageTitle': 'আপনার ভাষা বেছে নিন',
      'languageSubtitle': 'সেটিংস থেকে পরে বদলাতে পারবেন।',
      'english': 'ইংরেজি',
      'spanish': 'স্প্যানিশ',
      'bengali': 'বাংলা',
      'french': 'ফরাসি',
      'german': 'জার্মান',
      'arabic': 'আরবি',
      'continueAction': 'চালিয়ে যান',
      'documents': 'ডকুমেন্ট',
      'scan': 'স্ক্যান',
      'settings': 'সেটিংস',
      'newScan': 'নতুন স্ক্যান',
      'camera': 'ক্যামেরা',
      'gallery': 'গ্যালারি',
      'processQueue': 'বাকি পেজ চিনুন',
      'emptyTitle': 'এখনও ডকুমেন্ট নেই',
      'emptyBody': 'সার্চযোগ্য PDF বানাতে ছবি তুলুন বা ইমপোর্ট করুন।',
      'queued': 'প্রস্তুত',
      'processing': 'প্রসেস হচ্ছে',
      'complete': 'সম্পন্ন',
      'failed': 'ব্যর্থ',
      'pages': 'পৃষ্ঠা',
      'page': 'পৃষ্ঠা',
      'ocrQueueNote':
          'টেক্সট রিকগনিশন এই ডিভাইসেই চলে। ইন্টারনেট বা সার্ভার লাগে না।',
      'retry': 'আবার চেষ্টা',
      'exportPdf': 'PDF এক্সপোর্ট',
      'delete': 'মুছুন',
      'language': 'ভাষা',
      'privacyTitle': 'গোপনীয়তা',
      'privacyBody': 'ছবি ও এক্সট্র্যাক্ট করা লেখা এই ডিভাইসেই থাকে।',
      'networkTitle': 'লোকাল OCR',
      'networkBody': 'ক্যাপচার, টেক্সট রিকগনিশন, সেভ ও PDF অফলাইনে কাজ করে।',
      'exported': 'PDF এক্সপোর্ট হয়েছে',
      'sampleText': 'OCR শেষে এক্সট্র্যাক্ট করা লেখা এখানে দেখা যাবে।',
      'addPage': 'পৃষ্ঠা যোগ',
      'autoLanguage': 'স্বয়ংক্রিয়',
      'lastError': 'শেষ সমস্যা',
      'noCameraError': 'এই ডিভাইসে কোনো ক্যামেরা পাওয়া যায়নি।',
      'cameraPermissionError':
          'ক্যামেরা ব্যবহারের অনুমতি দেওয়া হয়নি। সেটিংস থেকে অনুমতি দিন।',
      'galleryPermissionError':
          'গ্যালারি ব্যবহারের অনুমতি দেওয়া হয়নি। সেটিংস থেকে অনুমতি দিন।',
      'unknownCaptureError': 'ছবি তুলতে বা ইমপোর্ট করতে ব্যর্থ হয়েছে।',
      'dismiss': 'বন্ধ করুন',
      'cameraUnavailableHelp':
          'ক্যামেরা অনুপলব্ধ। দয়া করে গ্যালারি থেকে ইমপোর্ট করুন।',
      'pendingPages': 'অপেক্ষমাণ পৃষ্ঠা',
      'pendingPage': 'অপেক্ষমাণ পৃষ্ঠা',
      'textCopied': 'টেক্সট ক্লিপবোর্ডে কপি করা হয়েছে।',
      'copyText': 'কপি করুন',
      'scanHeaderTitle': 'নতুন ডকুমেন্ট তৈরি করুন',
      'scanHeaderSubtitle': 'ছবি তুলতে বা ইমপোর্ট করতে সোর্স সিলেক্ট করুন।',
      'moreAppsTitle': 'Bengal Bytes-এর আরও অ্যাপস',
      'moreAppsSubtitle':
          'প্লে স্টোরে আমাদের অন্যান্য অফলাইন প্রোডাক্টিভিটি অ্যাপগুলো দেখুন।',
      'copyright': 'কপিরাইট © Bengal Bytes',
      'ocrLanguageSelect': 'টেক্সট রিকগনিশন ভাষা',
      'ocrLangLatin': 'ল্যাটিন (ইংরেজি, স্প্যানিশ ইত্যাদি)',
      'ocrLangBengali': 'বাংলা (বাংলা)',
      'ocrLangDevanagari': 'দেবনাগরী (হিন্দি ইত্যাদি)',
      'ocrLangChinese': 'চীনা (中文)',
      'ocrLangJapanese': 'জাপানি (日本語)',
      'ocrLangKorean': 'কোরিয়ান (한국어)',
      'ocrLangCyrillic': 'সিরিলিক (রাশিয়ান ইত্যাদি)',
    },
    'fr': {
      'appName': 'ScanVibe',
      'languageTitle': 'Choisissez votre langue',
      'languageSubtitle':
          'Vous pouvez changer cela à tout moment dans les Paramètres.',
      'english': 'Anglais',
      'spanish': 'Espagnol',
      'bengali': 'Bengali',
      'french': 'Français',
      'german': 'Allemand',
      'arabic': 'Arabe',
      'continueAction': 'Continuer',
      'documents': 'Documents',
      'scan': 'Numériser',
      'settings': 'Paramètres',
      'newScan': 'Nouvelle numérisation',
      'camera': 'Appareil photo',
      'gallery': 'Galerie',
      'processQueue': 'Reconnaître les pages en attente',
      'emptyTitle': 'Aucun document',
      'emptyBody': 'Prenez une photo ou importez une image pour commencer.',
      'queued': 'Prêt',
      'processing': 'Traitement',
      'complete': 'Terminé',
      'failed': 'Échoué',
      'pages': 'pages',
      'page': 'page',
      'ocrQueueNote':
          'La reconnaissance de texte s\'effectue sur cet appareil, sans connexion.',
      'retry': 'Réessayer',
      'exportPdf': 'Exporter en PDF',
      'delete': 'Supprimer',
      'language': 'Langue',
      'privacyTitle': 'Confidentialité',
      'privacyBody': 'Les images et textes extraits restent sur cet appareil.',
      'networkTitle': 'RCR Locale',
      'networkBody':
          'La capture, reconnaissance et l\'export PDF fonctionnent hors ligne.',
      'exported': 'PDF exporté',
      'sampleText': 'Le texte extrait apparaîtra ici après le RCR.',
      'addPage': 'Ajouter page',
      'autoLanguage': 'Détecter',
      'lastError': 'Dernier problème',
      'noCameraError': 'Aucun appareil photo disponible sur cet appareil.',
      'cameraPermissionError':
          'Accès à l\'appareil photo refusé. Veuillez l\'activer dans les Paramètres.',
      'galleryPermissionError':
          'Accès à la galerie refusé. Veuillez l\'activer dans les Paramètres.',
      'unknownCaptureError':
          'Échec de la capture ou de l\'importation de l\'image.',
      'dismiss': 'Fermer',
      'cameraUnavailableHelp':
          'Appareil photo indisponible. Veuillez importer depuis la galerie.',
      'pendingPages': 'pages en attente',
      'pendingPage': 'page en attente',
      'textCopied': 'Texte copié dans le presse-papiers.',
      'copyText': 'Copier le texte',
      'scanHeaderTitle': 'Créer un document',
      'scanHeaderSubtitle':
          'Choisissez une source pour capturer et extraire du texte.',
      'moreAppsTitle': 'Plus d\'applications de Bengal Bytes',
      'moreAppsSubtitle':
          'Découvrez nos autres outils de productivité hors ligne sur le Play Store.',
      'copyright': 'Copyright © Bengal Bytes',
      'ocrLanguageSelect': 'Langue de reconnaissance',
      'ocrLangLatin': 'Latin (anglais, espagnol, etc.)',
      'ocrLangBengali': 'Bengali (বাংলা)',
      'ocrLangDevanagari': 'Devanagari (hindi, etc.)',
      'ocrLangChinese': 'Chinois (中文)',
      'ocrLangJapanese': 'Japonais (日本語)',
      'ocrLangKorean': 'Coréen (한국어)',
      'ocrLangCyrillic': 'Cyrillique (russe, etc.)',
    },
    'de': {
      'appName': 'ScanVibe',
      'languageTitle': 'Wählen Sie Ihre Sprache',
      'languageSubtitle':
          'Sie können dies jederzeit in den Einstellungen ändern.',
      'english': 'Englisch',
      'spanish': 'Spanisch',
      'bengali': 'Bengalisch',
      'french': 'Französisch',
      'german': 'Deutsch',
      'arabic': 'Arabisch',
      'continueAction': 'Weiter',
      'documents': 'Dokumente',
      'scan': 'Scannen',
      'settings': 'Einstellungen',
      'newScan': 'Neuer Scan',
      'camera': 'Kamera',
      'gallery': 'Galerie',
      'processQueue': 'Ausstehende Seiten erkennen',
      'emptyTitle': 'Noch keine Dokumente',
      'emptyBody':
          'Nehmen Sie ein Foto auf oder importieren Sie ein Bild, um zu starten.',
      'queued': 'Bereit',
      'processing': 'Verarbeitung',
      'complete': 'Abgeschlossen',
      'failed': 'Fehlgeschlagen',
      'pages': 'Seiten',
      'page': 'Seite',
      'ocrQueueNote': 'Die Texterkennung läuft offline auf diesem Gerät.',
      'retry': 'Wiederholen',
      'exportPdf': 'PDF exportieren',
      'delete': 'Löschen',
      'language': 'Sprache',
      'privacyTitle': 'Datenschutz',
      'privacyBody':
          'Bilder und extrahierter Text verbleiben auf diesem Gerät.',
      'networkTitle': 'Lokales OCR',
      'networkBody':
          'Aufnahme, Texterkennung und PDF-Export funktionieren offline.',
      'exported': 'PDF exportiert',
      'sampleText': 'Extrahierter Text wird hier nach dem OCR angezeigt.',
      'addPage': 'Seite hinzufügen',
      'autoLanguage': 'Automatisch',
      'lastError': 'Letztes Problem',
      'noCameraError': 'Keine Kamera auf diesem Gerät verfügbar.',
      'cameraPermissionError':
          'Kamerazugriff verweigert. Bitte in den Einstellungen aktivieren.',
      'galleryPermissionError':
          'Galeriezugriff verweigert. Bitte in den Einstellungen aktivieren.',
      'unknownCaptureError': 'Bildaufnahme oder -import fehlgeschlagen.',
      'dismiss': 'Schließen',
      'cameraUnavailableHelp':
          'Kamera nicht verfügbar. Bitte aus der Galerie importieren.',
      'pendingPages': 'ausstehende Seiten',
      'pendingPage': 'ausstehende Seite',
      'textCopied': 'Text in die Zwischenablage kopiert.',
      'copyText': 'Text kopieren',
      'scanHeaderTitle': 'Neues Dokument erstellen',
      'scanHeaderSubtitle':
          'Wählen Sie eine Quelle zum Scannen und Extrahieren von Text.',
      'moreAppsTitle': 'Weitere Apps von Bengal Bytes',
      'moreAppsSubtitle':
          'Sehen Sie sich unsere anderen Offline-Produktivitäts-Tools im Play Store an.',
      'copyright': 'Copyright © Bengal Bytes',
      'ocrLanguageSelect': 'Erkennungssprache',
      'ocrLangLatin': 'Latein (Englisch, Spanisch, etc.)',
      'ocrLangBengali': 'Bengalisch (বাংলা)',
      'ocrLangDevanagari': 'Devanagari (Hindi, etc.)',
      'ocrLangChinese': 'Chinesisch (中文)',
      'ocrLangJapanese': 'Japanisch (日本語)',
      'ocrLangKorean': 'Koreanisch (한국어)',
      'ocrLangCyrillic': 'Kyrillisch (Russisch, etc.)',
    },
    'ar': {
      'appName': 'ScanVibe',
      'languageTitle': 'اختر لغتك',
      'languageSubtitle': 'يمكنك تغيير هذا في أي وقت من الإعدادات.',
      'english': 'الإنجليزية',
      'spanish': 'الإسبانية',
      'bengali': 'البنغالية',
      'french': 'الفرنسية',
      'german': 'الألمانية',
      'arabic': 'العربية',
      'continueAction': 'متابعة',
      'documents': 'المستندات',
      'scan': 'مسح ضوئي',
      'settings': 'الإعدادات',
      'newScan': 'مسح ضوئي جديد',
      'camera': 'الكاميرا',
      'gallery': 'المعرض',
      'processQueue': 'التعرف على الصفحات المعلقة',
      'emptyTitle': 'لا توجد مستندات بعد',
      'emptyBody': 'التقط صفحة أو استورد صورة لبدء ملف PDF قابل للبحث.',
      'queued': 'جاهز',
      'processing': 'جاري المعالجة',
      'complete': 'اكتمل',
      'failed': 'فشل',
      'pages': 'صفحات',
      'page': 'صفحة',
      'ocrQueueNote':
          'يتم التعرف على النصوص على هذا الجهاز. لا يلزم وجود إنترنت أو خادم.',
      'retry': 'إعادة المحاولة',
      'exportPdf': 'تصدير PDF',
      'delete': 'حذف',
      'language': 'اللغة',
      'privacyTitle': 'الخصوصية',
      'privacyBody':
          'تبقى الصور والنصوص المستخرجة على هذا الجهاز ما لم تقم بتصديرها أو مشاركتها.',
      'networkTitle': 'معالجة نصوص محلية (OCR)',
      'networkBody':
          'يعمل الالتقاط والتعرف على النصوص وحفظ المستندات وتصدير PDF دون اتصال بالإنترنت.',
      'exported': 'تم تصدير PDF',
      'sampleText': 'يظهر النص المستخرج هنا بعد التعرف عليه.',
      'addPage': 'إضافة صفحة',
      'autoLanguage': 'كشف تلقائي',
      'lastError': 'المشكلة الأخيرة',
      'noCameraError': 'لا توجد كاميرا متاحة على هذا الجهاز.',
      'cameraPermissionError':
          'تم رفض إذن الكاميرا. يرجى منح الوصول من الإعدادات.',
      'galleryPermissionError':
          'تم رفض إذن المعرض. يرجى منح الوصول من الإعدادات.',
      'unknownCaptureError': 'فشل التقاط أو استيراد الصورة.',
      'dismiss': 'إغلاق',
      'cameraUnavailableHelp':
          'الكاميرا غير متاحة. جرب استيراد الصور من المعرض بدلاً من ذلك.',
      'pendingPages': 'صفحات معلقة',
      'pendingPage': 'صفحة معلقة',
      'textCopied': 'تم نسخ النص إلى الحافظة.',
      'copyText': 'نسخ النص',
      'scanHeaderTitle': 'إنشاء مستند جديد',
      'scanHeaderSubtitle': 'اختر مصدراً للمسح الضوئي واستخراج النص.',
      'moreAppsTitle': 'المزيد من التطبيقات من Bengal Bytes',
      'moreAppsSubtitle':
          'تحقق من أدوات الإنتاجية الأخرى التي تعمل بدون اتصال بالإنترنت على متجر Play.',
      'copyright': 'حقوق النشر © Bengal Bytes',
      'ocrLanguageSelect': 'لغة التعرف',
      'ocrLangLatin': 'اللاتينية (الإنجليزية، الإسبانية، الفرنسية، الألمانية)',
      'ocrLangBengali': 'البنغالية (বাংলা)',
      'ocrLangDevanagari': 'الديواناجارية (الهندية، إلخ)',
      'ocrLangChinese': 'الصينية (中文)',
      'ocrLangJapanese': 'اليابانية (日本語)',
      'ocrLangKorean': 'الكورية (한국어)',
      'ocrLangCyrillic': 'السيريلية (الروسية، إلخ)',
    },
  };

  String text(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key]!;
  String pageCount(int count) =>
      '$count ${count == 1 ? text('page') : text('pages')}';
  String formatDate(DateTime date) =>
      DateFormat.yMMMd(locale.languageCode).add_jm().format(date);
}

class _ScanVibeLocalizationsDelegate
    extends LocalizationsDelegate<ScanVibeLocalizations> {
  const _ScanVibeLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ScanVibeLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<ScanVibeLocalizations> load(Locale locale) async {
    return ScanVibeLocalizations(locale);
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<ScanVibeLocalizations> old,
  ) => false;
}
