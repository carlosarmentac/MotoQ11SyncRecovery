import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/widgets/export_config_dialog.dart';
import '../../../core/storage/widgets/import_config_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../scanner/presentation/qr_scanner_dialog.dart';
import '../providers/patch_state_provider.dart';
import 'widgets/kit_size_selector.dart';
import 'widgets/node_flash_card.dart';
import 'widgets/placement_guide_card.dart';
import 'widgets/step_card.dart';
import 'widgets/test_suite_card.dart';
import 'widgets/wifi_setup_form.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class SetupWizardScreen extends ConsumerWidget {
  const SetupWizardScreen({super.key});

  Future<void> _handleScanMasterQr(BuildContext context, WidgetRef ref, String lang) async {
    final result = await QrScannerDialog.show(
      context,
      title: AppStrings.tr('label_master_node', lang),
      language: lang,
    );

    if (result != null) {
      final current = ref.read(masterNodeProvider);
      final updated = current.copy(
        serialNumber: result.serialNumber,
        macAddress: result.macAddress,
        ssidDefault: result.defaultSsid,
        wifiPassword: result.defaultPassword,
      );
      await ref.read(masterNodeProvider.notifier).update(updated);
    }
  }

  Future<void> _handleScanSatelliteQr(
    BuildContext context,
    WidgetRef ref,
    int index,
    String lang,
  ) async {
    final result = await QrScannerDialog.show(
      context,
      title: '${AppStrings.tr('label_satellite_node', lang)} ${index + 1}',
      language: lang,
    );

    if (result != null) {
      final satellites = ref.read(satellitesProvider);
      if (index < satellites.length) {
        final current = satellites[index];
        final updated = current.copy(
          serialNumber: result.serialNumber,
          macAddress: result.macAddress,
          ssidDefault: result.defaultSsid,
          wifiPassword: result.defaultPassword,
          name: current.name.isNotEmpty && !current.name.startsWith('Satellite Node')
              ? current.name
              : 'Satellite ${result.defaultSsid}',
        );
        await ref.read(satellitesProvider.notifier).updateSatellite(index, updated);
      }
    }
  }

  Future<void> _showResetConfirmation(BuildContext context, WidgetRef ref, String lang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
            const SizedBox(width: 8),
            Text(AppStrings.tr('btn_reset_all', lang)),
          ],
        ),
        content: Text(
          lang == 'es'
              ? '¿Está seguro de reiniciar toda la configuración y nodos registrados?'
              : 'Are you sure you want to reset all configuration and registered nodes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.tr('btn_cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              lang == 'es' ? 'Reiniciar' : 'Reset',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = ref.read(localStorageProvider);
      await storage.clearAll();
      ref.invalidate(kitSizeProvider);
      ref.invalidate(masterNodeProvider);
      ref.invalidate(satellitesProvider);
      ref.invalidate(wifiMeshConfigProvider);
      ref.invalidate(patchControllerProvider);
      ref.invalidate(testSuiteControllerProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final kitSize = ref.watch(kitSizeProvider);
    final master = ref.watch(masterNodeProvider);
    final satellites = ref.watch(satellitesProvider);
    final wifiConfig = ref.watch(wifiMeshConfigProvider);
    final patchState = ref.watch(patchControllerProvider);
    final testSuiteState = ref.watch(testSuiteControllerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('app_title', lang),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        AppStrings.tr('app_subtitle', lang),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: AppStrings.tr('btn_export_config', lang),
                icon: const Icon(Icons.ios_share, size: 20),
                onPressed: () {
                  final storage = ref.read(localStorageProvider);
                  final jsonStr = storage.exportFullConfigJson();
                  showDialog(
                    context: context,
                    builder: (ctx) => ExportConfigDialog(jsonText: jsonStr, language: lang),
                  );
                },
              ),
              IconButton(
                tooltip: AppStrings.tr('btn_import_config', lang),
                icon: const Icon(Icons.file_download, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ImportConfigDialog(language: lang),
                  );
                },
              ),
              IconButton(
                tooltip: AppStrings.tr('btn_reset_all', lang),
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => _showResetConfirmation(context, ref, lang),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Factory Reset Banner
                      _buildResetNotice(lang),
                      const SizedBox(height: 16),

                      // Step 1: Kit Size
                      StepCard(
                        stepNumber: 1,
                        title: AppStrings.tr('step1_title', lang),
                        description: AppStrings.tr('step1_desc', lang),
                        child: KitSizeSelector(
                          selectedSize: kitSize,
                          language: lang,
                          onKitSizeChanged: (size) async {
                            await ref.read(kitSizeProvider.notifier).setKitSize(size);
                            await ref.read(satellitesProvider.notifier).ensureSatelliteSlots(size - 1);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step 2: Wi-Fi Setup
                      StepCard(
                        stepNumber: 2,
                        title: AppStrings.tr('step2_title', lang),
                        description: AppStrings.tr('step2_desc', lang),
                        child: WifiSetupForm(
                          config: wifiConfig,
                          language: lang,
                          onConfigChanged: (newConfig) {
                            ref.read(wifiMeshConfigProvider.notifier).update(newConfig);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step 3: Flash Nodes
                      StepCard(
                        stepNumber: 3,
                        title: AppStrings.tr('step3_title', lang),
                        description: AppStrings.tr('step3_desc', lang),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Master node
                            NodeFlashCard(
                              title: AppStrings.tr('label_master_node', lang),
                              device: master,
                              isPatching: patchState.isPatching,
                              language: lang,
                              onScanQr: () => _handleScanMasterQr(context, ref, lang),
                              onDeviceChanged: (dev) {
                                ref.read(masterNodeProvider.notifier).update(dev);
                              },
                              onFlash: () {
                                ref.read(patchControllerProvider.notifier).flashMaster();
                              },
                            ),

                            // Satellite 1
                            if (kitSize >= 2 && satellites.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              NodeFlashCard(
                                title: '${AppStrings.tr('label_satellite_node', lang)} 1',
                                device: satellites[0],
                                isPatching: patchState.isPatching,
                                language: lang,
                                onScanQr: () => _handleScanSatelliteQr(context, ref, 0, lang),
                                onDeviceChanged: (dev) {
                                  ref.read(satellitesProvider.notifier).updateSatellite(0, dev);
                                },
                                onFlash: () {
                                  ref.read(patchControllerProvider.notifier).flashSatellite(0);
                                },
                              ),
                            ],

                            // Satellite 2
                            if (kitSize == 3 && satellites.length >= 2) ...[
                              const SizedBox(height: 14),
                              NodeFlashCard(
                                title: '${AppStrings.tr('label_satellite_node', lang)} 2',
                                device: satellites[1],
                                isPatching: patchState.isPatching,
                                language: lang,
                                onScanQr: () => _handleScanSatelliteQr(context, ref, 1, lang),
                                onDeviceChanged: (dev) {
                                  ref.read(satellitesProvider.notifier).updateSatellite(1, dev);
                                },
                                onFlash: () {
                                  ref.read(patchControllerProvider.notifier).flashSatellite(1);
                                },
                              ),
                            ],

                            // Terminal Patch Log Output
                            const SizedBox(height: 14),
                            _buildPatchTerminal(patchState),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step 4: Placement Guide
                      StepCard(
                        stepNumber: 4,
                        title: AppStrings.tr('step4_title', lang),
                        description: AppStrings.tr('step4_desc', lang),
                        child: PlacementGuideCard(language: lang),
                      ),
                      const SizedBox(height: 16),

                      // Step 5: Test Suite
                      StepCard(
                        stepNumber: 5,
                        title: AppStrings.tr('step5_title', lang),
                        description: AppStrings.tr('step5_desc', lang),
                        child: TestSuiteCard(
                          state: testSuiteState,
                          masterIp: master.ipAddress,
                          language: lang,
                          onRunTests: () {
                            ref.read(testSuiteControllerProvider.notifier).runSuite();
                          },
                          onGotoTopology: () {
                            ref.read(navigationIndexProvider.notifier).state = 1;
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetNotice(String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'es' ? 'AVISO PREVIO OBLIGATORIO' : 'MANDATORY PRE-REQUISITE',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tr('guide_factory_reset_desc', lang),
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatchTerminal(PatchingState patchState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: patchState.lastSuccess == true
              ? AppColors.success.withValues(alpha: 0.5)
              : patchState.lastSuccess == false
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              const Text(
                'Patch Engine Log',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (patchState.isPatching)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            patchState.log,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: patchState.lastSuccess == true
                  ? AppColors.success
                  : patchState.lastSuccess == false
                      ? AppColors.error
                      : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
