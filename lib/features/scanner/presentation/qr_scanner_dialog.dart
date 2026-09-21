import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/qr_scan_result.dart';
import '../utils/motorola_qr_parser.dart';

class QrScannerDialog extends StatefulWidget {
  final String title;
  final String language;

  const QrScannerDialog({
    super.key,
    required this.title,
    required this.language,
  });

  static Future<QrScanResult?> show(
    BuildContext context, {
    required String title,
    required String language,
  }) {
    return showDialog<QrScanResult>(
      context: context,
      builder: (ctx) => QrScannerDialog(title: title, language: language),
    );
  }

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _manualController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  String? _parseError;

  bool get _cameraSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _cameraSupported ? 2 : 1,
      vsync: this,
    );
    if (_cameraSupported) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _handleRawPayload(code);
        break;
      }
    }
  }

  void _handleRawPayload(String raw) {
    final parsed = MotorolaQrParser.parse(raw);
    if (parsed != null) {
      setState(() {
        _isProcessing = true;
        _parseError = null;
      });
      Navigator.of(context).pop(parsed);
    } else {
      setState(() {
        _parseError = 'Invalid Motorola Q11 QR Code format. Format: S/N:MAC:SSID:KEY';
      });
    }
  }

  void _submitManual() {
    final text = _manualController.text.trim();
    if (text.isEmpty) return;
    _handleRawPayload(text);
  }

  void _fillSampleQr() {
    _manualController.text = '2081AA001234:00:11:22:33:44:55:MOTO_Q11_TEST:secretPass99';
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.tr('scanner_title', lang),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // TabBar if camera is supported
              if (_cameraSupported)
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryLight,
                  labelColor: AppColors.primaryLight,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(icon: Icon(Icons.camera_alt, size: 18), text: 'Camera'),
                    Tab(icon: Icon(Icons.keyboard, size: 18), text: 'Manual'),
                  ],
                ),

              const SizedBox(height: 12),

              // Tab Content or Manual Only
              Expanded(
                child: _cameraSupported
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCameraView(lang),
                          _buildManualView(lang),
                        ],
                      )
                    : _buildManualView(lang),
              ),

              if (_parseError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _parseError!,
                          style: const TextStyle(color: AppColors.error, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView(String lang) {
    if (_scannerController == null) {
      return const Center(child: Text('Camera not initialized'));
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MobileScanner(
            controller: _scannerController!,
            onDetect: _onDetect,
          ),
        ),
        // Scanner reticle overlay
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryLight, width: 2.5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Positioned(
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppStrings.tr('scanner_hint', lang),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualView(String lang) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.tr('scanner_manual_paste', lang),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _manualController,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: 'e.g. 2081AA001234:00:11:22:33:44:55:Moto_Q11_Setup:myWifiPass123',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.paste, size: 14),
                label: const Text('Paste'),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _manualController.text = data!.text!;
                  }
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.science_outlined, size: 14),
                label: const Text('Sample QR'),
                onPressed: _fillSampleQr,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitManual,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
