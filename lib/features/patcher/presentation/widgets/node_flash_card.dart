import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../models/models.dart';

class NodeFlashCard extends StatelessWidget {
  final String title;
  final Q11Device device;
  final bool isPatching;
  final String language;
  final VoidCallback onScanQr;
  final ValueChanged<Q11Device> onDeviceChanged;
  final VoidCallback onFlash;

  const NodeFlashCard({
    super.key,
    required this.title,
    required this.device,
    required this.isPatching,
    required this.language,
    required this.onScanQr,
    required this.onDeviceChanged,
    required this.onFlash,
  });

  @override
  Widget build(BuildContext context) {
    final lang = language;
    final isCompleted = device.patchStatus == PatchStatus.completed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    device.role == NodeRole.master ? Icons.router : Icons.hub,
                    size: 18,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 13, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Patched & Linked',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: Text('${AppStrings.tr('btn_scan_qr', lang)} ($title)'),
            onPressed: isPatching ? null : onScanQr,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: device.ssidDefault,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('label_default_ssid', lang),
                  ),
                  onChanged: (val) => onDeviceChanged(device.copyWith(ssidDefault: val.trim())),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: device.wifiPassword,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('label_wifi_password', lang),
                  ),
                  onChanged: (val) => onDeviceChanged(device.copyWith(wifiPassword: val.trim())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: device.ipAddress,
            decoration: InputDecoration(
              labelText: AppStrings.tr('label_router_ip', lang),
            ),
            onChanged: (val) => onDeviceChanged(device.copyWith(ipAddress: val.trim())),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: isPatching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.build, size: 16),
            label: Text(
              device.role == NodeRole.master
                  ? AppStrings.tr('btn_flash_master', lang)
                  : AppStrings.tr('btn_flash_satellite', lang, [device.id]),
            ),
            onPressed: isPatching ? null : onFlash,
          ),
        ],
      ),
    );
  }
}
