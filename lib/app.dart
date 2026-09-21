import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/guides/presentation/hardware_guides_screen.dart';
import 'features/patcher/presentation/setup_wizard_screen.dart';
import 'features/topology/presentation/network_topology_view.dart';

class Q11SaverApp extends ConsumerWidget {
  const Q11SaverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Moto Q11 Rescue Utility',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final lang = ref.watch(languageProvider);

    final screens = const [
      SetupWizardScreen(),
      NetworkTopologyView(),
      HardwareGuidesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                ref.read(navigationIndexProvider.notifier).state = index;
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.build_outlined),
                  selectedIcon: const Icon(Icons.build),
                  label: AppStrings.tr('nav_setup', lang),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.hub_outlined),
                  selectedIcon: const Icon(Icons.hub),
                  label: AppStrings.tr('nav_topology', lang),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book),
                  label: AppStrings.tr('nav_guides', lang),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: lang == 'en' ? 'Cambiar a Español' : 'Switch to English',
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        onPressed: () {
          ref.read(languageProvider.notifier).toggleLanguage();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 14),
            const SizedBox(width: 2),
            Text(
              lang.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}
