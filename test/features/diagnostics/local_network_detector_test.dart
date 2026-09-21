import 'package:flutter_test/flutter_test.dart';
import 'package:motoq11_saver/features/diagnostics/utils/local_network_detector.dart';

void main() {
  group('LocalNetworkDetector', () {
    test('detects LAN IPs or runs gracefully', () async {
      final ips = await LocalNetworkDetector.detectLanIps();
      // On host with physical wifi/ethernet, it should find valid LAN IPs
      for (final ip in ips) {
        expect(ip.contains('.'), isTrue);
        final firstOctet = int.parse(ip.split('.').first);
        // Ensure not loopback or docker default bridge
        expect(firstOctet != 127, isTrue);
      }
    });

    test('detectSubnetPrefix produces valid base prefix', () async {
      final prefix = await LocalNetworkDetector.detectSubnetPrefix();
      expect(prefix.isNotEmpty, isTrue);
      final parts = prefix.split('.');
      expect(parts.length, equals(3));
    });

    test('detectDefaultRouterIp produces .1 ending or null', () async {
      final routerIp = await LocalNetworkDetector.detectDefaultRouterIp();
      if (routerIp != null) {
        expect(routerIp.endsWith('.1'), isTrue);
      }
    });
  });
}
