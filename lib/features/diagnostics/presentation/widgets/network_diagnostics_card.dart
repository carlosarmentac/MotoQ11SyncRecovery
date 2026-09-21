import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isMoto ? Icons.router : Icons.devices,
                                size: 16,
                                color: isMoto ? AppColors.primaryLight : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.ip,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isMoto
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isMoto ? AppColors.primaryLight : AppColors.border,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  roleText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isMoto ? AppColors.primaryLight : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Spacer(),
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
          ],
        ),
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
}
