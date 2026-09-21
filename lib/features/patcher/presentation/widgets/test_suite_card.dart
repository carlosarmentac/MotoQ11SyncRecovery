import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/patch_state_provider.dart';

class TestSuiteCard extends StatelessWidget {
  final TestSuiteState state;
  final String masterIp;
  final String language;
  final VoidCallback onRunTests;
  final VoidCallback onGotoTopology;

  const TestSuiteCard({
    super.key,
    required this.state,
    required this.masterIp,
    required this.language,
    required this.onRunTests,
    required this.onGotoTopology,
  });

  Future<void> _openAdminUrl() async {
    final uri = Uri.parse('http://$masterIp/cgi-bin/admin.sh');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = language;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: state.isRunning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.network_check, size: 18),
          label: Text(
            state.isRunning
                ? AppStrings.tr('test_status_running', lang)
                : AppStrings.tr('btn_run_tests', lang),
          ),
          onPressed: state.isRunning ? null : onRunTests,
        ),
        if (state.isRunning) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildCheckRow(
                icon: Icons.public,
                title: AppStrings.tr('test_check_internet', lang),
                status: state.internetOk,
              ),
              const Divider(color: AppColors.border, height: 16),
              _buildCheckRow(
                icon: Icons.router,
                title: AppStrings.tr('test_check_services', lang),
                status: state.servicesOk,
              ),
              const Divider(color: AppColors.border, height: 16),
              _buildCheckRow(
                icon: Icons.hub,
                title: AppStrings.tr('test_check_mesh', lang),
                status: state.satellitesOk,
              ),
              const Divider(color: AppColors.border, height: 16),
              Row(
                children: [
                  const Icon(Icons.devices, size: 18, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.tr('test_check_clients', lang),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    state.clientsCount != null
                        ? '${state.clientsCount} device(s)'
                        : 'Not scanned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (state.clientsCount ?? 0) > 0
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (state.summary != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (state.internetOk == true && state.servicesOk == true)
                  ? AppColors.successContainer.withValues(alpha: 0.4)
                  : AppColors.warningContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (state.internetOk == true && state.servicesOk == true)
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            child: Text(
              state.summary!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: (state.internetOk == true && state.servicesOk == true)
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 15),
                label: Text(
                  AppStrings.tr('btn_open_admin', lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _openAdminUrl,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.hub, size: 15),
                label: Text(
                  AppStrings.tr('btn_goto_topology', lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: onGotoTopology,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckRow({
    required IconData icon,
    required String title,
    required bool? status,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 12)),
        ),
        if (status == null)
          const Text('Pending', style: TextStyle(color: AppColors.textMuted, fontSize: 11))
        else if (status)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 16),
              SizedBox(width: 4),
              Text('PASS', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          )
        else
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: AppColors.error, size: 16),
              SizedBox(width: 4),
              Text('FAIL', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
      ],
    );
  }
}
