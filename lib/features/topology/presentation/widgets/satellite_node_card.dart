import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../models/models.dart';

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
                    Text(
                      AppStrings.tr('label_default_ssid', lang),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
          ],
        ),
      ),
    );
  }
}
