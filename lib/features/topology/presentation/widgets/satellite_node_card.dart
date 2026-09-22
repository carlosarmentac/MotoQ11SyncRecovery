import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../diagnostics/providers/diagnostics_provider.dart';
import '../../../models/models.dart';
import '../../../scanner/presentation/qr_scanner_dialog.dart';

class SatelliteNodeCard extends StatelessWidget {
  final Q11Device satellite;
  final String language;
  final VoidCallback onDelete;

  const SatelliteNodeCard({
    super.key,
    required this.satellite,
    required this.language,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lang = language;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wifi_tethering, color: AppColors.primaryLight, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      satellite.name.isNotEmpty
                          ? satellite.name
                          : 'Satellite ${satellite.ssidDefault}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_note, size: 16, color: AppColors.textSecondary),
                      tooltip: AppStrings.tr('btn_edit_friendly_name', lang),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () => _showRenameSatelliteDialog(context, lang),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Remove node',
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backhaul:',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      satellite.backhaul == BackhaulType.wifi5g
                          ? AppStrings.tr('backhaul_wifi', lang)
                          : AppStrings.tr('backhaul_ethernet', lang),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.tr('label_default_ssid', lang),
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 13, color: AppColors.textSecondary),
                          tooltip: AppStrings.tr('btn_edit_credentials', lang),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          onPressed: () => _showEditCredentialsSatelliteDialog(context, lang),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      satellite.ssidDefault,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('label_router_ip', lang),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      satellite.ipAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons: Open Admin, Open Terminal
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.admin_panel_settings, size: 14),
                    label: Text(
                      AppStrings.tr('btn_open_admin', lang),
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _launchUrl(context, 'http://${satellite.ipAddress}/cgi-bin/admin.sh'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.terminal, size: 14),
                    label: Text(
                      AppStrings.tr('btn_open_terminal', lang),
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () => _launchUrl(context, 'http://${satellite.ipAddress}:7681'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Secondary Actions: Flash LED (15s) and Device Stats
            Row(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final diagState = ref.watch(diagnosticsProvider);
                      final isFlashing = diagState.flashingNodeIps.contains(satellite.ipAddress);

                      return OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: isFlashing ? Colors.cyanAccent : AppColors.primaryLight,
                          side: BorderSide(
                            color: isFlashing ? Colors.cyanAccent : AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        icon: isFlashing
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                              )
                            : const Icon(Icons.lightbulb_outline, size: 14),
                        label: Text(
                          isFlashing ? 'Flashing...' : AppStrings.tr('btn_identify_led', lang),
                          style: const TextStyle(fontSize: 10),
                        ),
                        onPressed: isFlashing
                            ? null
                            : () async {
                                final notifier = ref.read(diagnosticsProvider.notifier);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppStrings.tr('flashing_led_toast', lang, [satellite.ipAddress])),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                await notifier.flashDeviceLed(satellite.ipAddress, satellite.wifiPassword);
                              },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      return OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.insights, size: 14),
                        label: Text(
                          AppStrings.tr('btn_device_stats', lang),
                          style: const TextStyle(fontSize: 10),
                        ),
                        onPressed: () => _showDeviceStatsDialog(context, ref, lang),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $url')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  void _showDeviceStatsDialog(BuildContext context, WidgetRef ref, String lang) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<DeviceTelemetry?>(
          future: ref.read(diagnosticsProvider.notifier).fetchDeviceStats(satellite.ipAddress, satellite.wifiPassword),
          builder: (context, snapshot) {
            final stats = snapshot.data;
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.tr('device_stats_title', lang)} (${satellite.ipAddress})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Querying router telemetry via SSH...', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      )
                    : stats == null
                        ? const Text('Could not retrieve telemetry. Ensure SSH is running.', style: TextStyle(fontSize: 12))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatRow(AppStrings.tr('uptime_label', lang), stats.uptime),
                                const Divider(height: 16),
                                _buildStatRow(AppStrings.tr('cpu_load_label', lang), stats.cpuLoad.toStringAsFixed(2)),
                                const Divider(height: 16),
                                _buildStatRow(
                                  AppStrings.tr('memory_usage_label', lang),
                                  '${stats.usedMemMb} MB / ${stats.totalMemMb} MB (${stats.memoryUsagePercent.toStringAsFixed(1)}%)',
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: stats.memoryUsagePercent / 100,
                                    backgroundColor: AppColors.surfaceVariant,
                                    color: stats.memoryUsagePercent > 85 ? AppColors.warning : AppColors.primary,
                                    minHeight: 6,
                                  ),
                                ),
                                const Divider(height: 20),
                                Text(
                                  AppStrings.tr('active_ssids_label', lang),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                if (stats.configuredSsids.isEmpty)
                                  Text(AppStrings.tr('no_ssids_found', lang), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                                else
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: stats.configuredSsids.map((ssid) {
                                      return Chip(
                                        avatar: const Icon(Icons.wifi, size: 14, color: AppColors.primaryLight),
                                        label: Text(ssid, style: const TextStyle(fontSize: 11)),
                                        backgroundColor: AppColors.surfaceVariant,
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppStrings.tr('btn_cancel', lang)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  void _showRenameSatelliteDialog(BuildContext context, String lang) {
    final controller = TextEditingController(text: satellite.name);
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.tr('btn_edit_friendly_name', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: ${satellite.ipAddress} ${satellite.mac.isNotEmpty ? "(${satellite.mac})" : ""}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppStrings.tr('label_friendly_name', lang),
                  hintText: AppStrings.tr('hint_friendly_name', lang),
                  prefixIcon: const Icon(Icons.label, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.tr('btn_cancel', lang)),
            ),
            if (satellite.name.isNotEmpty)
              TextButton(
                onPressed: () {
                  ref.read(diagnosticsProvider.notifier).updateDeviceCustomName(
                        satellite.ipAddress,
                        '',
                        macAddress: satellite.mac,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.tr('name_cleared_toast', lang))),
                  );
                },
                child: Text(
                  AppStrings.tr('btn_clear', lang),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                ref.read(diagnosticsProvider.notifier).updateDeviceCustomName(
                      satellite.ipAddress,
                      newName.isNotEmpty ? newName : 'Satellite ${satellite.ssidDefault}',
                      macAddress: satellite.mac,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.tr('name_saved_toast', lang))),
                );
              },
              child: Text(AppStrings.tr('btn_save', lang)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCredentialsSatelliteDialog(BuildContext context, String lang) {
    final ssidCtrl = TextEditingController(text: satellite.ssidDefault);
    final passCtrl = TextEditingController(text: satellite.wifiPassword);

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) => StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.wifi_password, color: AppColors.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.tr('edit_credentials_title', lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target: ${satellite.ipAddress} ${satellite.mac.isNotEmpty ? "(${satellite.mac})" : ""}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: Text(AppStrings.tr('btn_scan_qr', lang)),
                      onPressed: () async {
                        final qrResult = await QrScannerDialog.show(
                          context,
                          title: 'Satellite QR Label',
                          language: lang,
                        );
                        if (qrResult != null) {
                          setModalState(() {
                            ssidCtrl.text = qrResult.defaultSsid;
                            passCtrl.text = qrResult.defaultPassword;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ssidCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('label_default_ssid', lang),
                        hintText: 'q11-xxxx',
                        prefixIcon: const Icon(Icons.wifi, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('label_wifi_password', lang),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.tr('btn_cancel', lang)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newSsid = ssidCtrl.text.trim();
                    final newPass = passCtrl.text.trim();
                    final updated = satellite.copyWith(
                      ssidDefault: newSsid.isNotEmpty ? newSsid : satellite.ssidDefault,
                      wifiPassword: newPass,
                    );
                    ref.read(satellitesProvider.notifier).saveSatellite(updated);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.tr('credentials_saved_toast', lang))),
                    );
                  },
                  child: Text(AppStrings.tr('btn_save', lang)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
