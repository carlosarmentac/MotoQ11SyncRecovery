import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String? subtitle;
  final String? description;
  final bool isActive;
  final bool isCompleted;
  final Widget? content;
  final Widget? child;

  const StepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    this.subtitle,
    this.description,
    this.isActive = true,
    this.isCompleted = false,
    this.content,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final descText = subtitle ?? description ?? '';
    final bodyWidget = content ?? child ?? const SizedBox.shrink();

    return Card(
      color: isActive ? AppColors.surfaceCard : AppColors.surfaceCard.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive
              ? AppColors.primary
              : isCompleted
                  ? AppColors.success.withValues(alpha: 0.5)
                  : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.successContainer
                        : isActive
                            ? AppColors.primaryContainer
                            : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: AppColors.success)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            color: isActive ? AppColors.primaryLight : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isCompleted
                              ? AppColors.textPrimary
                              : isActive
                                  ? AppColors.primaryLight
                                  : AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      if (descText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          descText,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isActive || isCompleted) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              bodyWidget,
            ],
          ],
        ),
      ),
    );
  }
}
