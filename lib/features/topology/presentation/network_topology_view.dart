import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/widgets/export_config_dialog.dart';
import '../../../core/storage/widgets/import_config_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../diagnostics/presentation/widgets/network_diagnostics_card.dart';
import '../../diagnostics/providers/diagnostics_provider.dart';
import '../../diagnostics/utils/local_network_detector.dart';
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

  Future<void> _autoDetectAndScan() async {
    final prefix = await LocalNetworkDetector.detectSubnetPrefix(defaultFallback: '192.168.1');
    await ref.read(diagnosticsProvider.notifier).scanSubnet(prefix);
  }

  void _adoptDeviceAsMaster(SubnetScanResult item, String lang) {
    final currentMaster = ref.read(masterNodeProvider);
    final chosenName = item.customName.isNotEmpty
        ? item.customName
        : (item.role.isNotEmpty ? item.role : 'Master Gateway (${item.ip})');

    ref.read(masterNodeProvider.notifier).update(
      currentMaster.copyWith(
        ipAddress: item.ip,
        mac: item.macAddress,
        name: chosenName,
        isOnline: true,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppStrings.tr('device_added_toast', lang)} (${item.ip} -> Master)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _adoptDeviceAsSatellite(SubnetScanResult item, String lang) {
    final chosenName = item.customName.isNotEmpty
        ? item.customName
        : (item.role.isNotEmpty ? item.role : 'Satellite (${item.ip})');

    final newSat = Q11Device(
      id: 'sat-${DateTime.now().millisecondsSinceEpoch}',
      name: chosenName,
      role: NodeRole.satellite,
      ipAddress: item.ip,
      mac: item.macAddress,
      isOnline: true,
      backhaul: BackhaulType.wifi5g,
    );

    ref.read(satellitesProvider.notifier).addSatellite(newSat);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppStrings.tr('device_added_toast', lang)} (${item.ip} -> Satellite)'),
        duration: const Duration(seconds: 2),
      ),
    );
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
    final storage = ref.watch(localStorageProvider);

    final hasConfig = storage.hasConfiguredMaster() || satellites.isNotEmpty;

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
                tooltip: AppStrings.tr('btn_rescan_network', lang),
                icon: diagState.isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.radar, size: 20),
                onPressed: diagState.isScanning ? null : _autoDetectAndScan,
              ),
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
                      // Overview & Storage Badge Banner with Re-scan
                      _buildOverviewBanner(lang, master, diagState),
                      const SizedBox(height: 16),

                      // If network is unconfigured, show Auto-Detect Onboarding Banner
                      if (!hasConfig) ...[
                        _buildUnconfiguredNetworkBanner(lang, diagState),
                        const SizedBox(height: 16),
                      ],

                      // Discovered Devices Section (if scan results exist)
                      if (diagState.subnetResults.isNotEmpty) ...[
                        _buildDiscoveredNodesCard(lang, diagState, master, satellites),
                        const SizedBox(height: 16),
                      ],

                      // Interactive Animated Topology Mesh Canvas
                      _buildCanvasCard(master, satellites, diagState, lang),
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
                      const SizedBox(height: 20),

                      // Diagnostics & Subnet Scanner Card (Placed at bottom)
                      NetworkDiagnosticsCard(
                        defaultTargetIp: master.ipAddress,
                        language: lang,
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

  Widget _buildUnconfiguredNetworkBanner(String lang, DiagnosticsState diagState) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.wifi_find_rounded, color: AppColors.primaryLight, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('unconfigured_network_title', lang),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.tr('unconfigured_network_desc', lang),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (diagState.isScanning) ...[
              LinearProgressIndicator(
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scanning physical LAN subnet...',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    diagState.scanProgress,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.search, size: 18),
                  label: Text(
                    AppStrings.tr('btn_autodetect_scan', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _autoDetectAndScan,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredNodesCard(
    String lang,
    DiagnosticsState diagState,
    Q11Device currentMaster,
    List<Q11Device> currentSatellites,
  ) {
    final q11Nodes = diagState.subnetResults.where((r) => r.isQ11Device).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.devices_other, size: 18, color: AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Text(
                      '${AppStrings.tr('discovered_nodes_title', lang)} (${diagState.subnetResults.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: diagState.isScanning
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                        )
                      : const Icon(Icons.refresh, size: 14),
                  label: Text(
                    AppStrings.tr('btn_rescan_network', lang),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: diagState.isScanning ? null : _autoDetectAndScan,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: q11Nodes.isNotEmpty ? q11Nodes.length : diagState.subnetResults.length,
              separatorBuilder: (_, _) => const Divider(color: AppColors.border, height: 1),
              itemBuilder: (ctx, i) {
                final item = q11Nodes.isNotEmpty ? q11Nodes[i] : diagState.subnetResults[i];
                final isMoto = item.isQ11Device;
                final isMasterInTopology = currentMaster.ipAddress == item.ip;
                final isSatelliteInTopology = currentSatellites.any((s) => s.ipAddress == item.ip);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isMoto
                                ? (item.isMaster ? Icons.router : Icons.hub)
                                : Icons.devices,
                            size: 18,
                            color: isMoto ? AppColors.primaryLight : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.customName.isNotEmpty ? item.customName : item.ip,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (item.customName.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${item.ip})',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.isMaster
                                            ? Colors.amber.withValues(alpha: 0.2)
                                            : (isMoto
                                                ? AppColors.primary.withValues(alpha: 0.2)
                                                : AppColors.surfaceVariant),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.role.isNotEmpty
                                            ? item.role
                                            : (item.isMaster
                                                ? 'Master Gateway'
                                                : (isMoto ? 'Satellite Node' : 'Host')),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: item.isMaster
                                              ? Colors.amber[300]
                                              : (isMoto ? AppColors.primaryLight : AppColors.textSecondary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.border, width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.fingerprint, size: 12, color: AppColors.primaryLight),
                                          const SizedBox(width: 4),
                                          Text(
                                            'MAC: ${item.macAddress.isNotEmpty ? item.macAddress : "Unknown / Pending ARP"}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w600,
                                              color: item.macAddress.isNotEmpty ? Colors.white : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Ports: ${item.portsOpen.join(', ')}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isMasterInTopology)
                            const Chip(
                              label: Text('Active Master', style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                              backgroundColor: AppColors.surfaceVariant,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            )
                          else
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              icon: const Icon(Icons.star_border, size: 14),
                              label: Text(
                                AppStrings.tr('btn_set_as_master', lang),
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () => _adoptDeviceAsMaster(item, lang),
                            ),
                          const SizedBox(width: 8),
                          if (isSatelliteInTopology)
                            const Chip(
                              label: Text('In Mesh', style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                              backgroundColor: AppColors.surfaceVariant,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            )
                          else
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              icon: const Icon(Icons.add_link, size: 14),
                              label: Text(
                                AppStrings.tr('btn_add_as_satellite', lang),
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () => _adoptDeviceAsSatellite(item, lang),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            final textColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
            );

            final buttons = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: diagState.isScanning ? null : _autoDetectAndScan,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (diagState.isScanning)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                        )
                      else
                        const Icon(Icons.radar, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.tr('btn_rescan_network', lang),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: diagState.isRefreshingClients
                      ? null
                      : () => _handleRefresh(master.ipAddress, master.wifiPassword),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (diagState.isRefreshingClients)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.sync, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.tr('btn_refresh_network', lang),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textColumn,
                  const SizedBox(height: 10),
                  buttons,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: textColumn),
                buttons,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCanvasCard(
    Q11Device master,
    List<Q11Device> satellites,
    DiagnosticsState diagState,
    String lang,
  ) {
    final connectedIp = diagState.localConnectedNodeIp;

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
            child: Row(
              children: [
                const Icon(Icons.hub_outlined, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                const Text(
                  'Live Mesh Topology Canvas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (connectedIp != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.laptop_chromebook, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'You are on $connectedIp',
                          style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Text(
                  'Auto-sync',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: TopologyCanvasPainter(
                    masterNode: master,
                    satellites: satellites,
                    animationProgress: _pulseController.value,
                    localConnectedNodeIp: diagState.localConnectedNodeIp,
                    flashingNodeIps: diagState.flashingNodeIps,
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
