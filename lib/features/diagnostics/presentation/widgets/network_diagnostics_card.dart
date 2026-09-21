import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/diagnostics_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.defaultTargetIp);
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

            // Subnet Scan Button
            ElevatedButton.icon(
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
                    : AppStrings.tr('btn_scan_subnet', lang),
              ),
              onPressed: isBusy
                  ? null
                  : () {
                      final ip = _ipController.text.trim();
                      final prefix = ip.contains('.')
                          ? ip.substring(0, ip.lastIndexOf('.'))
                          : '192.168.1';
                      diagController.scanSubnet(prefix);
                    },
            ),

            // Subnet Scan Results List
            if (diagState.subnetResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Discovered Devices (${diagState.subnetResults.length}):',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.ip,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                item.isQ11Device
                                    ? 'Motorola Q11 (Ports: ${item.portsOpen.join(', ')})'
                                    : 'Network Host (Ports: ${item.portsOpen.join(', ')})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: item.isQ11Device
                                      ? AppColors.primaryLight
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${item.rttMs} ms',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
}
