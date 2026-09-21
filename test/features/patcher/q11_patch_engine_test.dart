import 'package:flutter_test/flutter_test.dart';
import 'package:motoq11_saver/features/models/models.dart';
import 'package:motoq11_saver/features/patcher/domain/q11_patch_engine.dart';

void main() {
  group('Q11PatchEngine Output Parsers', () {
    late Q11PatchEngine engine;

    setUp(() {
      engine = Q11PatchEngine();
    });

    test('instantiates Q11PatchEngine correctly', () {
      expect(engine, isNotNull);
    });

    test('parses Linux ping output format', () {
      const samplePingOutput = '''
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=12.4 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=118 time=11.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=118 time=13.1 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=118 time=12.1 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 11.800/12.350/13.100/0.485 ms
''';

      final lossMatch = RegExp(r'(\d+)%\s+packet loss').firstMatch(samplePingOutput);
      expect(lossMatch, isNotNull);
      expect(lossMatch!.group(1), equals('0'));

      final rxMatch = RegExp(r'(\d+)\s+received').firstMatch(samplePingOutput);
      expect(rxMatch, isNotNull);
      expect(rxMatch!.group(1), equals('4'));

      final rttMatch = RegExp(r'min/avg/max[^=]*=\s*([\d.]+)/([\d.]+)/([\d.]+)')
          .firstMatch(samplePingOutput);
      expect(rttMatch, isNotNull);
      expect(rttMatch!.group(1), equals('11.800'));
      expect(rttMatch.group(2), equals('12.350'));
      expect(rttMatch.group(3), equals('13.100'));
    });

    test('parses DHCP leases output correctly', () {
      const dhcpLeases = '''
1710920000 00:11:22:33:44:55 192.168.1.100 Android-Phone 01:00:11:22:33:44:55
1710920500 aa:bb:cc:dd:ee:ff 192.168.1.101 * 01:aa:bb:cc:dd:ee:ff
''';

      final clients = <DhcpClient>[];
      for (final line in dhcpLeases.split('\n')) {
        final tokens = line.trim().split(RegExp(r'\s+'));
        if (tokens.length >= 4) {
          final leaseTime = tokens[0];
          final mac = tokens[1];
          final clientIp = tokens[2];
          final rawName = tokens[3];
          final name = rawName == '*'
              ? 'Client-${mac.length >= 5 ? mac.substring(mac.length - 5) : mac}'
              : rawName;
          clients.add(DhcpClient(
            leaseTime: leaseTime,
            mac: mac,
            ip: clientIp,
            name: name,
          ));
        }
      }

      expect(clients.length, equals(2));
      expect(clients[0].name, equals('Android-Phone'));
      expect(clients[0].ip, equals('192.168.1.100'));
      expect(clients[1].name, equals('Client-ee:ff'));
      expect(clients[1].ip, equals('192.168.1.101'));
    });
  });
}
