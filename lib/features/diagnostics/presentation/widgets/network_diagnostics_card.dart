import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../providers/diagnostics_provider.dart';
import '../../utils/local_network_detector.dart';

class NetworkDiagnosticsCard extends ConsumerStatefulWidget {
  final String defaultTargetIp;
  final String language;

  const NetworkDiagnosticsCard({
    super.key,
    required this.defaultTargetIp,
    required this.language,
  });

  @override
  ConsumerState<NetworkDiagnosticsCard> createState() => _NetworkDiagnosticsCardState();
}

class _NetworkDiagnosticsCardState extends ConsumerState<NetworkDiagnosticsCard> {
  late TextEditingController _ipController;
  String? _detectedSubnetPrefix;
  bool _isDetectingLan = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.defaultTargetIp);
    _detectLocalLan();
  }

  Future<void> _detectLocalLan() async {
    setState(() => _isDetectingLan = true);
    final detectedRouter = await LocalNetworkDetector.detectDefaultRouterIp();
    final prefix = await LocalNetworkDetector.detectSubnetPrefix(
      defaultFallback: widget.defaultTargetIp.contains('.')
          ? widget.defaultTargetIp.substring(0, widget.defaultTargetIp.lastIndexOf('.'))
          : '192.168.1',
    );

    if (!mounted) return;

    setState(() {
      _isDetectingLan = false;
      _detectedSubnetPrefix = prefix;
      // If default was generic 192.168.1.1 and real LAN is detected (e.g. 10.10.11.1), update controller
      if (detectedRouter != null && (widget.defaultTargetIp == '192.168.1.1' || _ipController.text.isEmpty)) {
        _ipController.text = detectedRouter;
      }
    });
  }

  @override
  void didUpdateWidget(covariant NetworkDiagnosticsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultTargetIp != widget.defaultTargetIp &&
        _ipController.text.isEmpty) {
      _ipController.text = widget.defaultTargetIp;
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final diagState = ref.watch(diagnosticsProvider);
    final diagController = ref.read(diagnosticsProvider.notifier);
    final savedCustomNames = ref.watch(customDeviceNamesProvider);

    final isBusy = diagState.isRunningPing || diagState.isRunningTrace || diagState.isScanning;

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
            // Header
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: AppColors.primaryLight, size: 22),
                const SizedBox(width: 8),
                Text(
                  AppStrings.tr('diag_title', lang),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Subnet Scan Button & Detected Subnet Status
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: diagState.isScanning
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.radar, size: 18),
                    label: Text(
                      diagState.isScanning
                          ? 'Scanning (${diagState.scanProgress})...'
                          : '${AppStrings.tr('btn_scan_subnet', lang)}${_detectedSubnetPrefix != null ? ' ($_detectedSubnetPrefix.0/24)' : ''}',
                    ),
                    onPressed: isBusy
                        ? null
                        : () {
                            final ip = _ipController.text.trim();
                            final prefix = ip.contains('.')
                                ? ip.substring(0, ip.lastIndexOf('.'))
                                : (_detectedSubnetPrefix ?? '192.168.1');
                            diagController.scanSubnet(prefix);
                          },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Re-detect Physical LAN Subnet',
                  icon: _isDetectingLan
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find, size: 18),
                  onPressed: isBusy || _isDetectingLan ? null : _detectLocalLan,
                ),
              ],
            ),

            if (_detectedSubnetPrefix != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.lan, size: 13, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Active Physical LAN Subnet: $_detectedSubnetPrefix.0/24',
                    style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            // Subnet Scan Results List
            if (diagState.subnetResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discovered Devices (${diagState.subnetResults.length}):',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  Text(
                    '${diagState.subnetResults.where((r) => r.isQ11Device).length} Motorola Q11 nodes detected',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: diagState.subnetResults.length,
                  separatorBuilder: (_, _) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (ctx, i) {
                    final item = diagState.subnetResults[i];
                    final isMoto = item.isQ11Device;
                    final roleText = item.role.isNotEmpty
                        ? item.role
                        : (isMoto ? 'Motorola Q11 Node' : 'Standard Network Host');

                    final customName = item.customName.isNotEmpty
                        ? item.customName
                        : (savedCustomNames[item.macAddress.toLowerCase()] ??
                            savedCustomNames[item.ip] ??
                            '');
                    final displayName = customName.isNotEmpty ? customName : item.ip;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isMoto
                                    ? (item.isMaster ? Icons.router : Icons.hub)
                                    : Icons.devices,
                                size: 16,
                                color: isMoto ? AppColors.primaryLight : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          fontFamily: customName.isNotEmpty ? null : 'monospace',
                                          color: customName.isNotEmpty ? Colors.white : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (customName.isNotEmpty) ...[
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
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isMoto
                                      ? (item.isMaster
                                          ? AppColors.primary.withValues(alpha: 0.25)
                                          : AppColors.primaryContainer.withValues(alpha: 0.4))
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isMoto
                                        ? (item.isMaster ? AppColors.primaryLight : AppColors.secondary)
                                        : AppColors.border,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  roleText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isMoto
                                        ? (item.isMaster ? AppColors.primaryLight : AppColors.secondary)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_note, size: 16, color: AppColors.textSecondary),
                                tooltip: 'Set custom name for ${item.ip}',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                onPressed: () => _showRenameDialog(context, ref, item, customName),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.rttMs} ms',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item.macAddress.isNotEmpty) ...[
                                Text(
                                  'MAC: ${item.macAddress}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Text(
                                  'Services: ${_formatPorts(item.portsOpen)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Target IP Input
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: AppStrings.tr('diag_target_ip_label', lang),
                prefixIcon: const Icon(Icons.settings_ethernet, size: 18),
              ),
            ),
            const SizedBox(height: 10),

            // Ping and Tracepath Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: diagState.isRunningPing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sensors, size: 16),
                    label: Text(
                      AppStrings.tr('btn_ping', lang),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: isBusy
                        ? null
                        : () {
                            final ip = _ipController.text.trim();
                            if (ip.isNotEmpty) {
                              diagController.runPing(ip);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: diagState.isRunningTrace
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.route, size: 16),
                    label: Text(
                      AppStrings.tr('btn_tracepath', lang),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: isBusy
                        ? null
                        : () {
                            final ip = _ipController.text.trim();
                            if (ip.isNotEmpty) {
                              diagController.runTracepath(ip);
                            }
                          },
                  ),
                ),
              ],
            ),

            // Monospace Console Terminal Output
            if (diagState.consoleOutput.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    diagState.consoleOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.primaryLight,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),

            // Speedtest Section
            _buildSpeedtestSection(lang, diagState, diagController),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedtestSection(
    String lang,
    DiagnosticsState diagState,
    DiagnosticsController diagController,
  ) {
    final speed = diagState.speedtestResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.tr('speedtest_title', lang),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: speed.isRunning
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, size: 14),
              label: Text(
                speed.isRunning ? 'Testing...' : AppStrings.tr('btn_start_speedtest', lang),
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: speed.isRunning ? null : () => diagController.runSpeedTest(),
            ),
          ],
        ),
        if (speed.isRunning) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 6),
          Text(
            speed.statusMessage,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSpeedMetric(
                label: AppStrings.tr('speedtest_latency', lang),
                value: speed.pingMs > 0 ? '${speed.pingMs.toStringAsFixed(1)} ms' : '--',
                icon: Icons.timer_outlined,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSpeedMetric(
                label: AppStrings.tr('speedtest_jitter', lang),
                value: speed.jitterMs > 0 ? '${speed.jitterMs.toStringAsFixed(1)} ms' : '--',
                icon: Icons.grain,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSpeedMetric(
                label: AppStrings.tr('speedtest_download', lang),
                value: speed.downloadMbps > 0 ? '${speed.downloadMbps.toStringAsFixed(1)} Mbps' : '--',
                icon: Icons.download,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSpeedMetric(
                label: AppStrings.tr('speedtest_upload', lang),
                value: speed.uploadMbps > 0 ? '${speed.uploadMbps.toStringAsFixed(1)} Mbps' : '--',
                icon: Icons.upload,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _formatPorts(List<int> ports) {
    if (ports.isEmpty) return 'None detected';
    final serviceNames = {
      22: '22 (SSH Dropbear)',
      53: '53 (DNS)',
      80: '80 (HTTP Motosync UI)',
      443: '443 (HTTPS)',
      8080: '8080 (HTTP Alt)',
      7681: '7681 (ttyd Terminal)',
    };

    return ports.map((p) => serviceNames[p] ?? '$p').join(' • ');
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    SubnetScanResult item,
    String currentCustomName,
  ) {
    final controller = TextEditingController(text: currentCustomName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Icon(
              item.isMaster ? Icons.router : Icons.hub,
              color: AppColors.primaryLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Set Device Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target: ${item.ip} ${item.macAddress.isNotEmpty ? "(${item.macAddress})" : ""}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Role: ${item.role.isNotEmpty ? item.role : (item.isQ11Device ? "Motorola Q11 Node" : "Network Host")}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Friendly Device Name',
                hintText: item.isMaster ? 'Living Room Gateway' : 'Office Satellite',
                prefixIcon: const Icon(Icons.label, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (currentCustomName.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(diagnosticsProvider.notifier).updateDeviceCustomName(
                      item.ip,
                      '',
                      macAddress: item.macAddress,
                    );
                Navigator.pop(ctx);
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              ref.read(diagnosticsProvider.notifier).updateDeviceCustomName(
                    item.ip,
                    newName,
                    macAddress: item.macAddress,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save Name'),
          ),
        ],
      ),
    );
  }
}

