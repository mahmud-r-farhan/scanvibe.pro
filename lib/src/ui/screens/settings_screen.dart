import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../l10n/scanvibe_localizations.dart';
import '../widgets/language_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final ScanVibeState state;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('settings'))),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.text('language'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LanguagePicker(
                        selectedLocale: state.locale,
                        onChanged: state.setLocale,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(strings.text('privacyTitle')),
                  subtitle: Text(strings.text('privacyBody')),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.wifi_tethering_outlined),
                  title: Text(strings.text('networkTitle')),
                  subtitle: Text(strings.text('networkBody')),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shop_two_outlined),
                  title: Text(strings.text('moreAppsTitle')),
                  subtitle: Text(strings.text('moreAppsSubtitle')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final url = Uri.parse(
                      'https://play.google.com/store/apps/dev?id=5575287110629554716',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  strings.text('copyright'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
