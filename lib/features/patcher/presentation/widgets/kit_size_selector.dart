import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class KitSizeSelector extends StatelessWidget {
  final int selectedSize;
  final String language;
  final ValueChanged<int>? onSizeChanged;
  final ValueChanged<int>? onKitSizeChanged;
  final VoidCallback? onNext;

  const KitSizeSelector({
    super.key,
    required this.selectedSize,
    required this.language,
    this.onSizeChanged,
    this.onKitSizeChanged,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final options = [
      (1, AppStrings.tr('node_single', language)),
      (2, AppStrings.tr('node_two', language)),
      (3, AppStrings.tr('node_three', language)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final size = opt.$1;
            final label = opt.$2;
            final isSelected = selectedSize == size;

            return FilterChip(
              selected: isSelected,
              showCheckmark: true,
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selectedColor: AppColors.primaryContainer,
              checkmarkColor: AppColors.primaryLight,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              onSelected: (_) => (onSizeChanged ?? onKitSizeChanged)?.call(size),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.hub, size: 20, color: AppColors.primaryLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedSize == 1
                      ? 'Configuration: 1 Standalone Gateway (Master). Direct WAN modem uplink.'
                      : selectedSize == 2
                          ? 'Configuration: 1 Master Gateway + 1 Satellite Node. 5 GHz wireless mesh link.'
                          : 'Configuration: 1 Master Gateway + 2 Satellite Nodes. Whole-home mesh coverage.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onNext != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onNext,
            child: Text(AppStrings.tr('btn_next_wifi', language)),
          ),
        ],
      ],
    );
  }
}
