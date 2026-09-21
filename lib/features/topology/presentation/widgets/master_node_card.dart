import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../models/models.dart';

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
                    Text(
                      AppStrings.tr('label_default_ssid', lang),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
          ],
        ),
      ),
    );
  }
}
