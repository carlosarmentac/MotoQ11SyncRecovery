import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_strings.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';

class ImportConfigDialog extends ConsumerStatefulWidget {
  final String language;
  final VoidCallback? onImportSuccess;

  const ImportConfigDialog({
    super.key,
    required this.language,
    this.onImportSuccess,
  });

  @override
  ConsumerState<ImportConfigDialog> createState() => _ImportConfigDialogState();
}

class _ImportConfigDialogState extends ConsumerState<ImportConfigDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final storage = ref.read(localStorageProvider);
    final success = await storage.importFullConfigJson(text);

    if (!mounted) return;

    if (success) {
      // Invalidate app providers so state refreshes across all screens
      ref.invalidate(kitSizeProvider);
      ref.invalidate(languageProvider);
      ref.invalidate(masterNodeProvider);
      ref.invalidate(satellitesProvider);
      ref.invalidate(wifiMeshConfigProvider);
      ref.invalidate(customDeviceNamesProvider);

      widget.onImportSuccess?.call();

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('import_success_toast', widget.language)),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.tr('import_error_toast', widget.language);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.file_download, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.tr('import_dialog_title', lang),
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
              AppStrings.tr('import_dialog_desc', lang),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _errorMessage != null ? AppColors.error : AppColors.border,
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: '{\n  "version": 1,\n  "kitSize": 2,\n  ...\n}',
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                  contentPadding: EdgeInsets.all(10),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(AppStrings.tr('btn_cancel', lang)),
        ),
        ElevatedButton.icon(
          icon: _isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 14),
          label: Text(AppStrings.tr('btn_apply_import', lang)),
          onPressed: _isLoading ? null : _handleImport,
        ),
      ],
    );
  }
}
