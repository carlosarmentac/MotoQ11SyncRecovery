import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';

class HardwareGuidesScreen extends ConsumerWidget {
  const HardwareGuidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.tr('nav_guides', lang),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Author & Project Info Card
                  _buildAuthorCard(lang),
                  const SizedBox(height: 16),

                  // Factory Reset Pinhole Guide
                  _buildResetPinholeCard(lang),
                  const SizedBox(height: 16),

                  // Rear Ports Architecture Card
                  _buildPortsCard(lang),
                  const SizedBox(height: 16),

                  // Front LED Matrix Card
                  _buildLedMatrixCard(lang),
                  const SizedBox(height: 16),

                  // CGI Exploit & Rescue Architecture Note
                  _buildTechExploitCard(lang),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorCard(String lang) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Motorola Q11 OpenWrt Rescue Utility',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Engineered by Carlos Armenta • Cross-Platform Mobile Edition',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryLight),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang == 'es'
                        ? 'Herramienta de grado de ingeniería para rescatar, desbloquear OpenWrt y sincronizar routers Motorola Q11 (MH7601, MH7602, MH7603) sin depender de servicios de nube.'
                        : 'Engineering-grade rescue utility to unbrick, unlock OpenWrt, and coordinate Motorola Q11 mesh units without reliance on dead cloud services.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetPinholeCard(String lang) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.warning, width: 1.2),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_reset, color: AppColors.warning, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.tr('guide_reset_title', lang),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.tr('guide_reset_desc', lang),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            _buildResetStep('1', lang == 'es' ? 'Desconecte el cable de alimentación USB-C del router.' : 'Unplug the USB-C power cable from the router.'),
            _buildResetStep('2', lang == 'es' ? 'Con un clip o pin, mantenga presionado el botón RESET en la base.' : 'With a paperclip, press and hold the bottom RESET pinhole button.'),
            _buildResetStep('3', lang == 'es' ? 'Sin soltar el botón, vuelva a conectar el cable de corriente.' : 'Keep holding the button and plug the USB-C power cable back in.'),
            _buildResetStep('4', lang == 'es' ? 'Mantenga presionado durante 15 segundos hasta que el LED frontal parpadee rápido.' : 'Hold for 15 full seconds until the front LED pulses rapidly.'),
            _buildResetStep('5', lang == 'es' ? 'Suelte el botón y espere 90 segundos para que inicie en 192.168.1.1.' : 'Release the pin and wait 90 seconds for it to boot at 192.168.1.1.'),
          ],
        ),
      ),
    );
  }

  Widget _buildResetStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortsCard(String lang) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_input_component, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.tr('guide_ports_title', lang),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPortRow(
              icon: Icons.language,
              title: AppStrings.tr('port_wan_title', lang),
              desc: AppStrings.tr('port_wan_desc', lang),
              color: AppColors.primaryLight,
            ),
            const Divider(color: AppColors.border, height: 16),
            _buildPortRow(
              icon: Icons.settings_ethernet,
              title: AppStrings.tr('port_lan_title', lang),
              desc: AppStrings.tr('port_lan_desc', lang),
              color: AppColors.secondary,
            ),
            const Divider(color: AppColors.border, height: 16),
            _buildPortRow(
              icon: Icons.power,
              title: AppStrings.tr('port_usbc_title', lang),
              desc: AppStrings.tr('port_usbc_desc', lang),
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortRow({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLedMatrixCard(String lang) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.tr('guide_led_title', lang),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLedRow(
              dotColor: Colors.amber,
              title: AppStrings.tr('led_amber_title', lang),
              desc: AppStrings.tr('led_amber_desc', lang),
            ),
            const Divider(color: AppColors.border, height: 16),
            _buildLedRow(
              dotColor: Colors.blueAccent,
              title: AppStrings.tr('led_blue_title', lang),
              desc: AppStrings.tr('led_blue_desc', lang),
            ),
            const Divider(color: AppColors.border, height: 16),
            _buildLedRow(
              dotColor: Colors.white,
              title: AppStrings.tr('led_white_title', lang),
              desc: AppStrings.tr('led_white_desc', lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedRow({
    required Color dotColor,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechExploitCard(String lang) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surfaceVariant.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.terminal, color: AppColors.primaryLight, size: 20),
                SizedBox(width: 8),
                Text(
                  'Architecture & CGI Vector Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              lang == 'es'
                  ? 'El firmware de fábrica de Motorola Q11 posee un backdoor CGI no autenticado o con credenciales predeterminadas en el puerto 443/80. Esta aplicación envía un payload HTTP que activa el demonio dropbear SSH temporal en el puerto 22, inyecta las configuraciones de red mallada (mesh) y activa la consola LuCI y terminal ttyd.'
                  : 'Motorola Q11 stock firmware contains a legacy CGI interface accessible over HTTPS. This utility executes a targeted request to unlock Dropbear SSH on port 22, writes the persistent OpenWrt mesh configuration, and exposes LuCI Web Admin (port 80/8080) and ttyd terminal (port 7681).',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
