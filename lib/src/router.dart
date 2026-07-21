import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/app_shell.dart';
import 'ui/screens/onboarding/welcome_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/scan/scan_camera_screen.dart';
import 'ui/screens/scan/scan_review_screen.dart';
import 'ui/screens/scan/scan_batch_screen.dart';
import 'ui/screens/documents/documents_screen.dart';
import 'ui/screens/documents/folders_screen.dart';
import 'ui/screens/documents/folder_screen.dart';
import 'ui/screens/documents/document_detail_screen.dart';
import 'ui/screens/text/text_viewer_screen.dart';
import 'ui/screens/text/text_editor_screen.dart';
import 'ui/screens/export/export_screen.dart';
import 'ui/screens/settings/settings_screen.dart';
import 'ui/screens/settings/about_screen.dart';
import 'ui/screens/premium/premium_screen.dart';
import 'providers/settings_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(settingsProvider); // keep router reactive to settings changes

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Onboarding
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Main Shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/scan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScanCameraScreen(),
            ),
          ),
          GoRoute(
            path: '/documents',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DocumentsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes
      GoRoute(
        path: '/scan/review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ScanReviewScreen(
            imagePath: extra['imagePath'] as String? ?? '',
            scanMode: extra['scanMode'] as String? ?? 'document',
          );
        },
      ),
      GoRoute(
        path: '/scan/batch',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ScanBatchScreen(
            documentId: extra['documentId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/folders',
        builder: (context, state) => const FoldersScreen(),
      ),
      GoRoute(
        path: '/folders/:id',
        builder: (context, state) => FolderScreen(
          folderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/document/:id',
        builder: (context, state) => DocumentDetailScreen(
          documentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/text/view',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TextViewerScreen(
            text: extra['text'] as String? ?? '',
            title: extra['title'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/text/edit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TextEditorScreen(
            text: extra['text'] as String? ?? '',
            documentId: extra['documentId'] as String? ?? '',
            pageId: extra['pageId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/export/:id',
        builder: (context, state) => ExportScreen(
          documentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
    ],
  );
});
