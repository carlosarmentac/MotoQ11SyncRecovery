import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_strings.dart';
import '../../theme/app_colors.dart';

class ExportConfigDialog extends StatelessWidget {
  final String jsonText;
  final String language;

  const ExportConfigDialog({
    super.key,
    required this.jsonText,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final lang = language;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.ios_share, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.tr('export_dialog_title', lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.tr('export_dialog_desc', lang),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.tr('btn_cancel', lang)),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy, size: 14),
          label: Text(AppStrings.tr('btn_copy_json', lang)),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: jsonText));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.tr('export_success_toast', lang))),
            );
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.share, size: 14),
          label: Text(AppStrings.tr('btn_share_json', lang)),
          onPressed: () {
            Share.share(jsonText, subject: 'Motorola Q11 Network Configuration Backup');
          },
        ),
      ],
    );
  }
}
