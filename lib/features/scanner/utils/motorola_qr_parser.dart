import '../../models/qr_scan_result.dart';

class MotorolaQrParser {
  /// Parses raw QR/barcode strings from Motorola Q11 bottom labels.
  /// Supports:
  /// 1. Standard WiFi URI format: `WIFI:S:q11-xxxx;T:WPA;P:password;;`
  /// 2. Key-value label text: `SSID: q11-xxxx PWD: password MAC: 00:11:22... SN: ...`
  /// 3. Fallback heuristic: token beginning with `q11-` and an 8-24 character password token.
  static QrScanResult? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();

    // 1. Standard WiFi URI string
    if (text.toUpperCase().startsWith('WIFI:')) {
      String ssid = '';
      String password = '';
      final payload = text.substring(5);
      final parts = payload.split(';');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.toUpperCase().startsWith('S:')) {
          ssid = trimmed.substring(2);
        } else if (trimmed.toUpperCase().startsWith('P:')) {
          password = trimmed.substring(2);
        }
      }
      if (ssid.isNotEmpty) {
        return QrScanResult(ssid: ssid, password: password);
      }
    }

    // 2. Key-Value label format (split by newline, semicolon, or comma)
    String ssid = '';
    String pass = '';
    String mac = '';
    String sn = '';

    final lines = text.split(RegExp(r'[\n;,]'));
    for (final line in lines) {
      final kv = line.split(RegExp(r'[:=]'));
      if (kv.length >= 2) {
        final key = kv[0].trim().toUpperCase();
        final value = kv.sublist(1).join(':').trim();
        if (key.contains('SSID') || key == 'S') {
          ssid = value;
        } else if (key.contains('PWD') ||
            key.contains('PASS') ||
            key.contains('KEY') ||
            key == 'P') {
          pass = value;
        } else if (key.contains('MAC')) {
          mac = value;
        } else if (key.contains('SN') || key.contains('SERIAL')) {
          sn = value;
        }
      }
    }

    if (ssid.isNotEmpty) {
      return QrScanResult(
        ssid: ssid,
        password: pass,
        mac: mac,
        serialNumber: sn,
      );
    }

    // 3. Fallback heuristic: look for token starting with "q11-"
    if (text.toLowerCase().contains('q11-')) {
      final tokens = text.split(RegExp(r'\s+'));
      for (final token in tokens) {
        final cleanToken = token.trim();
        if (cleanToken.toLowerCase().startsWith('q11-') && ssid.isEmpty) {
          ssid = cleanToken;
        } else if (cleanToken.length >= 8 &&
            cleanToken.length <= 24 &&
            pass.isEmpty &&
            !cleanToken.contains(':')) {
          pass = cleanToken;
        }
      }
      if (ssid.isNotEmpty) {
        return QrScanResult(ssid: ssid, password: pass);
      }
    }

    return null;
  }
}
