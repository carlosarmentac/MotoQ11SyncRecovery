import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../diagnostics/providers/diagnostics_provider.dart';
import '../../../models/models.dart';
import '../../../scanner/presentation/qr_scanner_dialog.dart';

class MasterNodeCard extends StatelessWidget {
  final Q11Device node;
  final String language;
  final VoidCallback? onRefresh;

  const MasterNodeCard({
    super.key,
    required this.node,
    required this.language,
    this.onRefresh,
  });

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

  @override
  Widget build(BuildContext context) {
    final lang = language;
    final isPatched = node.patchStatus == PatchStatus.completed;

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
            // Header: Status dot + Node Name + Patched Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: node.isOnline ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      node.name.isNotEmpty ? node.name : 'Master Gateway (Q11)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_note, size: 18, color: AppColors.textSecondary),
                      tooltip: AppStrings.tr('btn_edit_friendly_name', lang),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => _showRenameMasterDialog(context, lang),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPatched ? AppColors.successContainer : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPatched
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    isPatched
                        ? AppStrings.tr('status_patched', lang)
                        : AppStrings.tr('status_unpatched', lang),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPatched ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.border, height: 1),
            ),

            // Metadata Row: IP, SSID, WAN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('label_router_ip', lang),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.ipAddress,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primaryLight,
                      ),
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
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                          tooltip: AppStrings.tr('btn_edit_credentials', lang),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          onPressed: () => _showEditCredentialsMasterDialog(context, lang),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.ssidDefault,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WAN Port',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          node.isOnline ? Icons.check_circle : Icons.warning_amber_rounded,
                          size: 14,
                          color: node.isOnline ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          node.isOnline ? 'Online' : 'Pending',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: node.isOnline ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Actions: Open Admin, Open Web Terminal
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: Text(
                      AppStrings.tr('btn_open_admin', lang),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _launchUrl(context, 'http://${node.ipAddress}/cgi-bin/admin.sh'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.terminal, size: 16),
                    label: Text(
                      AppStrings.tr('btn_open_terminal', lang),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _launchUrl(context, 'http://${node.ipAddress}:7681'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Secondary Quick Actions: Flash LED (15s) and Device Stats
            Row(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final diagState = ref.watch(diagnosticsProvider);
                      final isFlashing = diagState.flashingNodeIps.contains(node.ipAddress);

                      return OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFlashing ? Colors.cyanAccent : AppColors.primaryLight,
                          side: BorderSide(
                            color: isFlashing ? Colors.cyanAccent : AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        icon: isFlashing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                              )
                            : const Icon(Icons.lightbulb_outline, size: 16),
                        label: Text(
                          isFlashing ? 'Flashing (15s)...' : AppStrings.tr('btn_identify_led', lang),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: isFlashing
                            ? null
                            : () async {
                                final notifier = ref.read(diagnosticsProvider.notifier);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppStrings.tr('flashing_led_toast', lang, [node.ipAddress])),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                await notifier.flashDeviceLed(node.ipAddress, node.wifiPassword);
                              },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      return OutlinedButton.icon(
                        icon: const Icon(Icons.insights, size: 16),
                        label: Text(
                          AppStrings.tr('btn_device_stats', lang),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _showDeviceStatsDialog(context, ref, lang),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tertiary Quick Actions: Device Config Backup & Restore
            Row(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      return OutlinedButton.icon(
                        icon: const Icon(Icons.download_for_offline_outlined, size: 15),
                        label: Text(
                          AppStrings.tr('btn_backup_device', lang),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _handleBackupDeviceConfig(context, ref, lang),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      return OutlinedButton.icon(
                        icon: const Icon(Icons.settings_backup_restore_outlined, size: 15),
                        label: Text(
                          AppStrings.tr('btn_restore_device', lang),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _handleRestoreDeviceConfig(context, ref, lang),
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

  void _showDeviceStatsDialog(BuildContext context, WidgetRef ref, String lang) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<DeviceTelemetry?>(
          future: ref.read(diagnosticsProvider.notifier).fetchDeviceStats(node.ipAddress, node.wifiPassword),
          builder: (context, snapshot) {
            final stats = snapshot.data;
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.primaryLight, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.tr('device_stats_title', lang)} (${node.ipAddress})',
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

  /// Ask for SSH password if wifiPassword is empty or if the operation requires it.
  Future<String?> _promptSshPassword(BuildContext context, String nodeIp, String currentPassword) async {
    if (currentPassword.isNotEmpty) return currentPassword;

    final controller = TextEditingController();
    bool obscure = true;

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_open, size: 20, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Expanded(child: Text('SSH Password for $nodeIp', style: const TextStyle(fontSize: 14))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the root SSH password for this device. Common defaults: empty, "admin", or your Wi-Fi password.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'SSH Root Password',
                  hintText: 'Leave empty to try no password',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (val) => Navigator.of(ctx).pop(val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  void _handleBackupDeviceConfig(BuildContext context, WidgetRef ref, String lang) async {
    // Prompt for SSH password if not configured
    final password = await _promptSshPassword(context, node.ipAddress, node.wifiPassword);
    if (password == null || !context.mounted) return; // user cancelled

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final base64Tar = await ref.read(diagnosticsProvider.notifier).backupDeviceConfig(
          node.ipAddress,
          password,
        );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) return;

    if (base64Tar != null && base64Tar.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppStrings.tr('btn_backup_device', lang)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.tr('device_backup_success', lang)),
              const SizedBox(height: 12),
              const Text('Raw /etc/config archive (Base64 tar.gz):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: SelectableText(
                    base64Tar,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.tr('btn_cancel', lang)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to backup config over SSH.')),
      );
    }
  }

  void _handleRestoreDeviceConfig(BuildContext context, WidgetRef ref, String lang) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${AppStrings.tr('btn_restore_device', lang)} (${node.ipAddress})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the Base64 configuration tarball to restore /etc/config on the device:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'H4sIC...',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.tr('btn_cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop();

              // Prompt for SSH password before restore
              if (!context.mounted) return;
              final password = await _promptSshPassword(context, node.ipAddress, node.wifiPassword);
              if (password == null || !context.mounted) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
              );

              final success = await ref.read(diagnosticsProvider.notifier).restoreDeviceConfig(
                    node.ipAddress,
                    password,
                    text,
                  );

              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? AppStrings.tr('device_restore_success', lang, [node.ipAddress])
                          : AppStrings.tr('device_restore_failed', lang),
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text(AppStrings.tr('btn_restore_device', lang)),
          ),
        ],
      ),
    );
  }

  void _showRenameMasterDialog(BuildContext context, String lang) {
    final controller = TextEditingController(text: node.name);
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
                'Target: ${node.ipAddress} ${node.mac.isNotEmpty ? "(${node.mac})" : ""}',
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
            if (node.name.isNotEmpty)
              TextButton(
                onPressed: () {
                  ref.read(diagnosticsProvider.notifier).updateDeviceCustomName(
                        node.ipAddress,
                        '',
                        macAddress: node.mac,
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
                      node.ipAddress,
                      newName.isNotEmpty ? newName : 'Master Gateway',
                      macAddress: node.mac,
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

  void _showEditCredentialsMasterDialog(BuildContext context, String lang) {
    final ssidCtrl = TextEditingController(text: node.ssidDefault);
    final passCtrl = TextEditingController(text: node.wifiPassword);

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
                      'Target: ${node.ipAddress} ${node.mac.isNotEmpty ? "(${node.mac})" : ""}',
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
                          title: 'Master Router QR Label',
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
                    final updated = node.copyWith(
                      ssidDefault: newSsid.isNotEmpty ? newSsid : node.ssidDefault,
                      wifiPassword: newPass,
                    );
                    ref.read(masterNodeProvider.notifier).saveMasterNode(updated);
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
