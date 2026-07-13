import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/scanvibe_localizations.dart';
import 'screens/documents_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});

  final ScanVibeState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.description_outlined),
        selectedIcon: const Icon(Icons.description),
        label: strings.text('documents'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.document_scanner_outlined),
        selectedIcon: const Icon(Icons.document_scanner),
        label: strings.text('scan'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: strings.text('settings'),
      ),
    ];
    final screens = [
      DocumentsScreen(state: widget.state),
      ScanScreen(state: widget.state),
      SettingsScreen(state: widget.state),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: screens[_index]),
              ],
            ),
          );
        }
        return Scaffold(
          body: screens[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: destinations,
          ),
        );
      },
    );
  }
}
