import 'dart:io';

class LocalNetworkDetector {
  LocalNetworkDetector._();

  static const List<String> _virtualInterfacePrefixes = [
    'docker',
    'br-',
    'veth',
    'tun',
    'tap',
    'tailscale',
    'wg',
    'wireguard',
    'virbr',
    'vmnet',
    'vboxnet',
    'ham',
    'zt',
    'ppp',
    'dummy',
  ];

  /// Detects candidate local LAN IPv4 addresses from physical network interfaces.
  /// Filters out loopback, virtual interfaces (docker, bridge, vpn, etc.), and link-local addresses.
  static Future<List<String>> detectLanIps() async {
    final results = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();

        // Exclude virtual/container/VPN interfaces by prefix
        final isVirtual = _virtualInterfacePrefixes.any((prefix) => name.startsWith(prefix));
        if (isVirtual) continue;

        for (final addr in iface.addresses) {
          if (addr.type != InternetAddressType.IPv4) continue;
          final ip = addr.address;

          if (_isCandidateLanIp(ip)) {
            results.add(ip);
          }
        }
      }
    } catch (_) {
      // Fallback on error
    }

    return results;
  }

  /// Suggests the best local LAN gateway IP or router candidate (e.g. 192.168.1.1, 10.10.11.1).
  /// If the host has a valid LAN IP, it returns the base network with .1 or the router address.
  static Future<String?> detectDefaultRouterIp() async {
    final ips = await detectLanIps();
    if (ips.isEmpty) return null;

    final primaryIp = ips.first;
    final lastDot = primaryIp.lastIndexOf('.');
    if (lastDot != -1) {
      final prefix = primaryIp.substring(0, lastDot);
      return '$prefix.1';
    }
    return primaryIp;
  }

  /// Suggests the local subnet base prefix (e.g. "192.168.1" or "10.10.11").
  static Future<String> detectSubnetPrefix({String defaultFallback = '192.168.1'}) async {
    final ips = await detectLanIps();
    if (ips.isEmpty) return defaultFallback;

    final primaryIp = ips.first;
    final lastDot = primaryIp.lastIndexOf('.');
    if (lastDot != -1) {
      return primaryIp.substring(0, lastDot);
    }
    return defaultFallback;
  }

  /// Validates standard RFC 1918 private IPv4 ranges:
  /// - 10.0.0.0/8
  /// - 172.16.0.0/12 (172.16.0.0 to 172.31.255.255)
  /// - 192.168.0.0/16
  /// Excludes 127.x, 169.254.x (link-local), and 0.0.0.0
  static bool _isCandidateLanIp(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) {
      return false;
    }

    final p0 = parts[0]!;
    final p1 = parts[1]!;

    // 10.0.0.0/8
    if (p0 == 10) return true;

    // 192.168.0.0/16
    if (p0 == 192 && p1 == 168) return true;

    // 172.16.0.0/12 (172.16 to 172.31)
    if (p0 == 172 && p1 >= 16 && p1 <= 31) {
      // Typically Docker bridges default to 172.17.x, 172.18.x, 172.19.x, 172.20.x, etc.
      // But if the interface is physical (not filtered above), it's permitted.
      return true;
    }

    return false;
  }
}
