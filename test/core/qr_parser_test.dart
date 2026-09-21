import 'package:flutter_test/flutter_test.dart';
import 'package:motoq11_saver/features/scanner/utils/motorola_qr_parser.dart';

void main() {
  group('MotorolaQrParser', () {
    test('parses standard WiFi URI QR code', () {
      const raw = 'WIFI:S:q11-7601;T:WPA;P:MySecretPass123;;';
      final result = MotorolaQrParser.parse(raw);
      expect(result, isNotNull);
      expect(result!.ssid, equals('q11-7601'));
      expect(result.password, equals('MySecretPass123'));
    });

    test('parses key-value multiline label text', () {
      const raw = '''
SSID: q11-alpha
PWD: SuperPassword99
MAC: 00:11:22:33:44:55
SN: MOT123456789
''';
      final result = MotorolaQrParser.parse(raw);
      expect(result, isNotNull);
      expect(result!.ssid, equals('q11-alpha'));
      expect(result.password, equals('SuperPassword99'));
      expect(result.mac, equals('00:11:22:33:44:55'));
      expect(result.serialNumber, equals('MOT123456789'));
    });

    test('parses comma-separated key-value text', () {
      const raw = 'SSID: q11-bravo, PASS: TokenPassWord123, MAC: AA:BB:CC:DD:EE:FF';
      final result = MotorolaQrParser.parse(raw);
      expect(result, isNotNull);
      expect(result!.ssid, equals('q11-bravo'));
      expect(result.password, equals('TokenPassWord123'));
      expect(result.mac, equals('AA:BB:CC:DD:EE:FF'));
    });

    test('handles fallback token parsing', () {
      const raw = 'Router Unit q11-charlie DefaultPassword888 Model MH7603';
      final result = MotorolaQrParser.parse(raw);
      expect(result, isNotNull);
      expect(result!.ssid, equals('q11-charlie'));
      expect(result.password, equals('DefaultPassword888'));
    });

    test('returns null for empty or invalid input', () {
      expect(MotorolaQrParser.parse(null), isNull);
      expect(MotorolaQrParser.parse(''), isNull);
      expect(MotorolaQrParser.parse('   '), isNull);
      expect(MotorolaQrParser.parse('just random text'), isNull);
    });
  });
}
