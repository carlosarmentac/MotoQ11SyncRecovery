import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class PlacementGuideCard extends StatelessWidget {
  final String language;
  final VoidCallback? onConfirm;

  const PlacementGuideCard({
    super.key,
    required this.language,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final lang = language;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr('step_4_master_instruction', lang),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.tr('step_4_satellite_instruction', lang),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.tr('step_4_led_instruction', lang),
                style: const TextStyle(fontSize: 12, color: AppColors.success, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPortBadge(Icons.language, 'WAN', 'To Modem', AppColors.primaryLight),
            _buildPortBadge(Icons.power, 'Power', '5V 3A USB-C', AppColors.warning),
            _buildPortBadge(Icons.check_circle_outline, 'Solid White', 'Online Mesh', AppColors.success),
          ],
        ),
        if (onConfirm != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onConfirm,
            child: Text(AppStrings.tr('btn_confirm_placement', lang)),
          ),
        ],
      ],
    );
  }

  Widget _buildPortBadge(IconData icon, String title, String detail, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        Text(detail, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
      ],
    );
  }
}
