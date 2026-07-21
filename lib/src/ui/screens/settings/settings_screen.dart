import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/settings_provider.dart';
import '../../../theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Premium Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _PremiumCard(onTap: () => context.push('/premium')),
              ),
            ),

            // General Section
            SliverToBoxAdapter(
              child: _SettingsSection(
                title: 'General',
                children: [
                  // Language
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    iconColor: AppColors.info,
                    title: 'Language',
                    subtitle: _getLanguageName(settings.locale.languageCode),
                    onTap: () => _showLanguagePicker(context, ref),
                  ),
                  // Theme
                  _SettingsTile(
                    icon: settings.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    iconColor: settings.isDarkMode
                        ? AppColors.secondaryLight
                        : AppColors.warning,
                    title: 'Theme',
                    subtitle: settings.isDarkMode ? 'Dark Mode' : 'Light Mode',
                    trailing: Switch(
                      value: settings.isDarkMode,
                      onChanged: (_) => ref.read(settingsProvider.notifier).toggleDarkMode(),
                    ),
                  ),
                ],
              ),
            ),

            // Scanning Section
            SliverToBoxAdapter(
              child: _SettingsSection(
                title: 'Scanning',
                children: [
                  _SettingsTile(
                    icon: Icons.document_scanner_rounded,
                    iconColor: AppColors.primaryLight,
                    title: 'Default Scan Mode',
                    subtitle: _getScanModeName(settings.defaultScanMode),
                    onTap: () => _showScanModePicker(context, ref),
                  ),
                  _SettingsTile(
                    icon: Icons.filter_rounded,
                    iconColor: AppColors.secondaryLight,
                    title: 'Default Filter',
                    subtitle: _getFilterName(settings.defaultFilter),
                    onTap: () => _showFilterPicker(context, ref),
                  ),
                  _SettingsTile(
                    icon: Icons.camera_enhance_rounded,
                    iconColor: AppColors.success,
                    title: 'Auto-Capture',
                    subtitle: 'Automatically capture when edges are detected',
                    trailing: Switch(
                      value: settings.autoCapture,
                      onChanged: (_) =>
                          ref.read(settingsProvider.notifier).setAutoCapture(!settings.autoCapture),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.auto_fix_high_rounded,
                    iconColor: AppColors.info,
                    title: 'Auto-Process OCR',
                    subtitle: 'Process text recognition automatically after capture',
                    trailing: Switch(
                      value: settings.autoProcessOcr,
                      onChanged: (_) => ref
                          .read(settingsProvider.notifier)
                          .setAutoProcessOcr(!settings.autoProcessOcr),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.translate_rounded,
                    iconColor: AppColors.warning,
                    title: 'OCR Language',
                    subtitle: _getOcrLanguageName(settings.ocrLanguage),
                    onTap: () => _showOcrLanguagePicker(context, ref),
                  ),
                ],
              ),
            ),

            // Export Section
            SliverToBoxAdapter(
              child: _SettingsSection(
                title: 'Export',
                children: [
                  _SettingsTile(
                    icon: Icons.image_rounded,
                    iconColor: AppColors.primaryLight,
                    title: 'Image Quality',
                    subtitle: '${(settings.imageQuality * 100).toInt()}%',
                    onTap: () => _showQualityPicker(context, ref),
                  ),
                ],
              ),
            ),

            // About Section
            SliverToBoxAdapter(
              child: _SettingsSection(
                title: 'About',
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.info,
                    title: 'About ScanVibe Pro',
                    subtitle: 'Version 2.0.0',
                    onTap: () => context.push('/about'),
                  ),
                  _SettingsTile(
                    icon: Icons.star_outline_rounded,
                    iconColor: AppColors.warning,
                    title: 'Rate App',
                    subtitle: 'Rate us on the Play Store',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Footer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'ScanVibe Pro v2.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\u00a9 2025 Bengal Bytes. All rights reserved.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    return switch (code) {
      'en' => 'English',
      'es' => 'Espa\u00f1ol',
      'bn' => '\u09ac\u09be\u0982\u09b2\u09be',
      'fr' => 'Fran\u00e7ais',
      'de' => 'Deutsch',
      'ar' => '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
      _ => 'English',
    };
  }

  String _getScanModeName(String mode) {
    return switch (mode) {
      'document' => 'Document',
      'id_card' => 'ID Card',
      'whiteboard' => 'Whiteboard',
      'qr_code' => 'QR Code',
      'book' => 'Book',
      'receipt' => 'Receipt',
      _ => 'Document',
    };
  }

  String _getFilterName(String filter) {
    return switch (filter) {
      'auto_enhance' => 'Auto Enhance',
      'black_white' => 'Black & White',
      'grayscale' => 'Grayscale',
      'magic_color' => 'Magic Color',
      'sharpen' => 'Sharpen',
      'clean' => 'Clean',
      _ => 'Auto Enhance',
    };
  }

  String _getOcrLanguageName(String lang) {
    return switch (lang) {
      'latin' => 'Latin (English, etc.)',
      'devanagari' => 'Devanagari (Hindi, etc.)',
      'chinese' => 'Chinese',
      'japanese' => 'Japanese',
      'korean' => 'Korean',
      _ => 'Latin',
    };
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Espa\u00f1ol'),
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(const Locale('es'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('\u09ac\u09be\u0982\u09b2\u09be'),
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(const Locale('bn'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Fran\u00e7ais'),
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(const Locale('fr'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Deutsch'),
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(const Locale('de'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('\u0627\u0644\u0639\u0631\u0628\u064a\u0629'),
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showScanModePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Default Scan Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...['document', 'id_card', 'whiteboard', 'qr_code', 'book', 'receipt'].map(
              (mode) => ListTile(
                title: Text(_getScanModeName(mode)),
                onTap: () {
                  ref.read(settingsProvider.notifier).setDefaultScanMode(mode);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Default Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...['auto_enhance', 'black_white', 'grayscale', 'magic_color', 'sharpen', 'clean'].map(
              (filter) => ListTile(
                title: Text(_getFilterName(filter)),
                onTap: () {
                  ref.read(settingsProvider.notifier).setDefaultFilter(filter);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOcrLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('OCR Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...['latin', 'devanagari', 'chinese', 'japanese', 'korean'].map(
              (lang) => ListTile(
                title: Text(_getOcrLanguageName(lang)),
                onTap: () {
                  ref.read(settingsProvider.notifier).setOcrLanguage(lang);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualityPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Image Quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...[0.7, 0.8, 0.85, 0.9, 0.92, 0.95, 1.0].map(
              (quality) => ListTile(
                title: Text('${(quality * 100).toInt()}%'),
                subtitle: Text(quality >= 0.95 ? 'Maximum quality' : quality >= 0.9 ? 'High quality' : 'Standard quality'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Unlock all features',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: children.asMap().entries.map((entry) {
                final isLast = entry.key == children.length - 1;
                return Column(
                  children: [
                    entry.value,
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
      onTap: onTap,
    );
  }
}
