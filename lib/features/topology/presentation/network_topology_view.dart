import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/widgets/export_config_dialog.dart';
import '../../../core/storage/widgets/import_config_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../diagnostics/presentation/widgets/network_diagnostics_card.dart';
import '../../diagnostics/providers/diagnostics_provider.dart';
import '../../models/models.dart';
import 'painters/topology_canvas_painter.dart';
import 'widgets/add_satellite_dialog.dart';
import 'widgets/master_node_card.dart';
import 'widgets/satellite_node_card.dart';

class NetworkTopologyView extends ConsumerStatefulWidget {
  const NetworkTopologyView({super.key});

  @override
  ConsumerState<NetworkTopologyView> createState() => _NetworkTopologyViewState();
}

class _NetworkTopologyViewState extends ConsumerState<NetworkTopologyView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(String masterIp, String wifiPassword) async {
    await ref.read(diagnosticsProvider.notifier).refreshClients(masterIp, wifiPassword);
  }

  void _showAddSatelliteDialog(BuildContext context, String lang) {
    AddSatelliteDialog.show(
      context,
      language: lang,
      onSave: (newSat) {
        ref.read(satellitesProvider.notifier).addSatellite(newSat);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final master = ref.watch(masterNodeProvider);
    final satellites = ref.watch(satellitesProvider);
    final diagState = ref.watch(diagnosticsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: Text(
              AppStrings.tr('nav_topology', lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: AppStrings.tr('btn_refresh_network', lang),
                icon: diagState.isRefreshingClients
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh, size: 20),
                onPressed: diagState.isRefreshingClients
                    ? null
                    : () => _handleRefresh(master.ipAddress, master.wifiPassword),
              ),
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
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview & Storage Badge Banner
                      _buildOverviewBanner(lang, master, diagState),
                      const SizedBox(height: 16),

                      // Interactive Animated Topology Mesh Canvas
                      _buildCanvasCard(master, satellites),
                      const SizedBox(height: 16),

                      // Master Node Section
                      Text(
                        AppStrings.tr('role_master', lang),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MasterNodeCard(
                        node: master,
                        language: lang,
                        onRefresh: () => _handleRefresh(master.ipAddress, master.wifiPassword),
                      ),
                      const SizedBox(height: 16),

                      // Diagnostics & Subnet Scanner Card
                      NetworkDiagnosticsCard(
                        defaultTargetIp: master.ipAddress,
                        language: lang,
                      ),
                      const SizedBox(height: 16),

                      // Satellites Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppStrings.tr('role_satellite', lang)} (${satellites.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(
                              AppStrings.tr('btn_add_satellite', lang),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _showAddSatelliteDialog(context, lang),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (satellites.isEmpty)
                        Card(
                          elevation: 0,
                          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                AppStrings.tr('no_satellites_added', lang),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: satellites.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final sat = satellites[i];
                            return SatelliteNodeCard(
                              satellite: sat,
                              language: lang,
                              onDelete: () {
                                ref.read(satellitesProvider.notifier).removeSatellite(sat.id);
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 16),

                      // DHCP Clients Section
                      Text(
                        '${AppStrings.tr('active_devices_title', lang)} (${diagState.dhcpClients.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (diagState.dhcpClients.isEmpty)
                        Card(
                          elevation: 0,
                          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                AppStrings.tr('no_devices_found', lang),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: diagState.dhcpClients.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final client = diagState.dhcpClients[i];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.devices, color: AppColors.primaryLight, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            client.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${client.ip} • ${client.mac}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

  Widget _buildOverviewBanner(String lang, Q11Device master, DiagnosticsState diagState) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.tr('network_overview', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.tr('local_storage_badge', lang),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              icon: diagState.isRefreshingClients
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync, size: 16),
              label: Text(
                AppStrings.tr('btn_refresh_network', lang),
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: diagState.isRefreshingClients
                  ? null
                  : () => _handleRefresh(master.ipAddress, master.wifiPassword),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasCard(Q11Device master, List<Q11Device> satellites) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.surface,
            child: const Row(
              children: [
                Icon(Icons.hub_outlined, size: 16, color: AppColors.primaryLight),
                SizedBox(width: 8),
                Text(
                  'Live Mesh Topology Canvas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Text(
                  'Auto-sync',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: TopologyCanvasPainter(
                    masterNode: master,
                    satellites: satellites,
                    animationProgress: _pulseController.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
