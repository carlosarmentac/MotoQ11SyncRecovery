import 'dart:io';

class ArpHelper {
  ArpHelper._();

  /// Reads the system ARP table to map IP addresses to MAC addresses.
  /// Works across Linux (`/proc/net/arp` and `ip neigh`), Android, and fallback CLI.
  static Future<Map<String, String>> getArpTable() async {
    final map = <String, String>{};

    // 1. Primary: Linux /proc/net/arp
    try {
      final file = File('/proc/net/arp');
      if (await file.exists()) {
        final content = await file.readAsString();
        for (final line in content.split('\n')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 4 && parts[0] != 'IP') {
            final ip = parts[0];
            final flags = parts[2];
            final mac = parts[3].toLowerCase();
            // Flag 0x2 means resolved/reachable (not 0x0 incomplete)
            if (mac != '00:00:00:00:00:00' && mac.contains(':') && flags != '0x0') {
              map[ip] = mac;
            }
          }
        }
      }
    } catch (_) {}

    // 2. Secondary: `ip neigh show` (captures dynamic STALE, REACHABLE, DELAY entries)
    try {
      final res = await Process.run('ip', ['neigh', 'show']);
      if (res.exitCode == 0) {
        final lines = (res.stdout as String).split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          final lladdrIndex = parts.indexOf('lladdr');
          if (lladdrIndex != -1 && lladdrIndex + 1 < parts.length && parts.isNotEmpty) {
            final ip = parts[0];
            final mac = parts[lladdrIndex + 1].toLowerCase();
            if (mac.contains(':') && mac != '00:00:00:00:00:00') {
              map[ip] ??= mac;
            }
          }
        }
      }
    } catch (_) {}

    // 3. Fallback: `arp -a` or `arp -n`
    try {
      final res = await Process.run('arp', ['-n']);
      if (res.exitCode == 0) {
        final lines = (res.stdout as String).split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 3) {
            final ip = parts[0].replaceAll(RegExp(r'[()]'), '');
            final mac = parts[2].toLowerCase();
            if (mac.contains(':') && mac != '00:00:00:00:00:00') {
              map[ip] ??= mac;
            }
          }
        }
      }
    } catch (_) {}

    return map;
  }

  /// Fast lookup of a single IP's MAC address from the ARP table.
  static Future<String?> getMacForIp(String ip) async {
    final table = await getArpTable();
    return table[ip];
  }
}
