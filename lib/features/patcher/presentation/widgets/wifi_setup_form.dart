import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../models/models.dart';

class WifiSetupForm extends StatefulWidget {
  final WifiMeshConfig? initialConfig;
  final WifiMeshConfig? config;
  final String language;
  final ValueChanged<WifiMeshConfig>? onSave;
  final ValueChanged<WifiMeshConfig>? onConfigChanged;

  const WifiSetupForm({
    super.key,
    this.initialConfig,
    this.config,
    required this.language,
    this.onSave,
    this.onConfigChanged,
  });

  @override
  State<WifiSetupForm> createState() => _WifiSetupFormState();
}

class _WifiSetupFormState extends State<WifiSetupForm> {
  late TextEditingController _home24Ssid;
  late TextEditingController _home24Pass;
  late TextEditingController _home5Ssid;
  late TextEditingController _home5Pass;
  late TextEditingController _guest24Ssid;
  late TextEditingController _guest24Pass;
  late TextEditingController _guest5Ssid;
  late TextEditingController _guest5Pass;
  bool _showPasswords = false;

  WifiMeshConfig get _activeConfig =>
      widget.config ?? widget.initialConfig ?? const WifiMeshConfig();

  @override
  void initState() {
    super.initState();
    _home24Ssid = TextEditingController(text: _activeConfig.home24Ssid);
    _home24Pass = TextEditingController(text: _activeConfig.home24Pass);
    _home5Ssid = TextEditingController(text: _activeConfig.home5Ssid);
    _home5Pass = TextEditingController(text: _activeConfig.home5Pass);
    _guest24Ssid = TextEditingController(text: _activeConfig.guest24Ssid);
    _guest24Pass = TextEditingController(text: _activeConfig.guest24Pass);
    _guest5Ssid = TextEditingController(text: _activeConfig.guest5Ssid);
    _guest5Pass = TextEditingController(text: _activeConfig.guest5Pass);
  }

  @override
  void dispose() {
    _home24Ssid.dispose();
    _home24Pass.dispose();
    _home5Ssid.dispose();
    _home5Pass.dispose();
    _guest24Ssid.dispose();
    _guest24Pass.dispose();
    _guest5Ssid.dispose();
    _guest5Pass.dispose();
    super.dispose();
  }

  void _save() {
    final updated = WifiMeshConfig(
      home24Ssid: _home24Ssid.text.trim(),
      home24Pass: _home24Pass.text.trim(),
      home5Ssid: _home5Ssid.text.trim(),
      home5Pass: _home5Pass.text.trim(),
      guest24Ssid: _guest24Ssid.text.trim(),
      guest24Pass: _guest24Pass.text.trim(),
      guest5Ssid: _guest5Ssid.text.trim(),
      guest5Pass: _guest5Pass.text.trim(),
    );
    (widget.onSave ?? widget.onConfigChanged)?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.tr('home_network_title', lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            IconButton(
              icon: Icon(
                _showPasswords ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _showPasswords = !_showPasswords),
              tooltip: 'Toggle password visibility',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _home24Ssid,
                decoration: const InputDecoration(labelText: 'Home 2.4 GHz SSID'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _home24Pass,
                obscureText: !_showPasswords,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _home5Ssid,
                decoration: const InputDecoration(labelText: 'Home 5 GHz SSID'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _home5Pass,
                obscureText: !_showPasswords,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.tr('guest_network_title', lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _guest24Ssid,
                decoration: const InputDecoration(labelText: 'Guest 2.4 GHz SSID'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _guest24Pass,
                obscureText: !_showPasswords,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _guest5Ssid,
                decoration: const InputDecoration(labelText: 'Guest 5 GHz SSID'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _guest5Pass,
                obscureText: !_showPasswords,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _save,
          child: Text(AppStrings.tr('btn_save_and_flash', lang)),
        ),
      ],
    );
  }
}
