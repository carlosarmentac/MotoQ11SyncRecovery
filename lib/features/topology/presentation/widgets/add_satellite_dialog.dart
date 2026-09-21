import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../scanner/presentation/qr_scanner_dialog.dart';

class AddSatelliteDialog extends StatefulWidget {
  final String language;
  final ValueChanged<Q11Device> onSave;

  const AddSatelliteDialog({
    super.key,
    required this.language,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String language,
    required ValueChanged<Q11Device> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AddSatelliteDialog(
        language: language,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddSatelliteDialog> createState() => _AddSatelliteDialogState();
}

class _AddSatelliteDialogState extends State<AddSatelliteDialog> {
  final _nameController = TextEditingController(text: 'Satellite Node');
  final _ssidController = TextEditingController(text: 'q11-');
  final _passwordController = TextEditingController();
  final _ipController = TextEditingController(text: '192.168.1.2');
  BackhaulType _backhaul = BackhaulType.wifi5g;

  @override
  void dispose() {
    _nameController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _handleScanQr() async {
    final result = await QrScannerDialog.show(
      context,
      title: 'Satellite QR Code',
      language: widget.language,
    );

    if (result != null) {
      setState(() {
        _ssidController.text = result.defaultSsid;
        _passwordController.text = result.defaultPassword;
      });
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();
    final ip = _ipController.text.trim();

    final device = Q11Device(
      id: 'sat-${DateTime.now().millisecondsSinceEpoch}',
      name: name.isNotEmpty ? name : 'Satellite $ssid',
      role: NodeRole.satellite,
      ssidDefault: ssid,
      wifiPassword: password,
      ipAddress: ip.isNotEmpty ? ip : '192.168.1.2',
      backhaul: _backhaul,
      patchStatus: PatchStatus.pending,
      isOnline: false,
    );

    widget.onSave(device);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.tr('btn_add_satellite', lang),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(AppStrings.tr('btn_scan_qr', lang)),
                  onPressed: _handleScanQr,
                ),

                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR MANUAL ENTRY',
                        style: TextStyle(fontSize: 10, color: AppColors.textDisabled, letterSpacing: 1),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Node Name',
                    hintText: 'e.g. Living Room Mesh',
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _ssidController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('label_default_ssid', lang),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('label_wifi_password', lang),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('label_router_ip', lang),
                  ),
                ),
                const SizedBox(height: 12),

                // Backhaul toggle
                Row(
                  children: [
                    const Text('Backhaul: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(AppStrings.tr('backhaul_wifi', lang)),
                      selected: _backhaul == BackhaulType.wifi5g,
                      onSelected: (val) {
                        if (val) setState(() => _backhaul = BackhaulType.wifi5g);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(AppStrings.tr('backhaul_ethernet', lang)),
                      selected: _backhaul == BackhaulType.ethernet,
                      onSelected: (val) {
                        if (val) setState(() => _backhaul = BackhaulType.ethernet);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.tr('btn_cancel', lang)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Save Satellite'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
