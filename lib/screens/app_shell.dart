import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/navigation_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/audio_deep_link_listener.dart';
import '../widgets/audio_mini_player.dart';
import 'bible_reader_screen.dart';
import 'dashboard_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'study_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();
    final l10n = AppLocalizations.of(context);
    final t = context.colors;
    final index = navigation.selectedIndex.clamp(0, 4);

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: l10n.navRead,
      ),
      NavigationDestination(
        icon: const Icon(Icons.check_box_outlined),
        selectedIcon: const Icon(Icons.check_box),
        label: l10n.navStudy,
      ),
      NavigationDestination(
        icon: const Icon(Icons.search_outlined),
        selectedIcon: const Icon(Icons.search),
        label: l10n.navSearch,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: l10n.navSettings,
      ),
    ];

    const pages = [
      DashboardScreen(),
      BibleReaderScreen(),
      StudyScreen(),
      SearchScreen(),
      SettingsScreen(),
    ];

    final content = IndexedStack(index: index, children: pages);
    final stackedContent = Stack(
      children: [
        Positioned.fill(child: content),
        const Positioned(
            left: 12, right: 12, bottom: 12, child: AudioMiniPlayer()),
      ],
    );

    return AudioDeepLinkListener(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRail = constraints.maxWidth >= 720;

          if (useRail) {
            return Scaffold(
              backgroundColor: t.appBg,
              body: SafeArea(
                child: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: navigation.setIndex,
                      labelType: constraints.maxWidth >= 1000
                          ? NavigationRailLabelType.all
                          : NavigationRailLabelType.selected,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text.rich(
                          TextSpan(
                            style: AppTheme.brandTitle(
                              fontSize: 18,
                              color: t.ink,
                            ),
                            children: const [
                              TextSpan(text: 'Bible'),
                              TextSpan(
                                text: 'Pulse',
                                style: TextStyle(color: AppTheme.gold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home),
                          label: Text(l10n.navHome),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.menu_book_outlined),
                          selectedIcon: const Icon(Icons.menu_book),
                          label: Text(l10n.navRead),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.check_box_outlined),
                          selectedIcon: const Icon(Icons.check_box),
                          label: Text(l10n.navStudy),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.search_outlined),
                          selectedIcon: const Icon(Icons.search),
                          label: Text(l10n.navSearch),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.person_outline),
                          selectedIcon: const Icon(Icons.person),
                          label: Text(l10n.navSettings),
                        ),
                      ],
                    ),
                    VerticalDivider(width: 1, color: t.border),
                    Expanded(child: stackedContent),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: t.appBg,
            body: stackedContent,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: t.surface,
                border: Border(top: BorderSide(color: t.border)),
              ),
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: navigation.setIndex,
                destinations: destinations,
              ),
            ),
          );
        },
      ),
    );
  }
}
