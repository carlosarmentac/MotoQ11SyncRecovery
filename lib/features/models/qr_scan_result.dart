class QrScanResult {
  final String ssid;
  final String password;
  final String mac;
  final String serialNumber;

  const QrScanResult({
    required this.ssid,
    required this.password,
    this.mac = '',
    this.serialNumber = '',
  });

  String get defaultSsid => ssid;
  String get defaultPassword => password;
  String get macAddress => mac;

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'password': password,
        'mac': mac,
        'serialNumber': serialNumber,
      };

  factory QrScanResult.fromJson(Map<String, dynamic> json) => QrScanResult(
        ssid: json['ssid'] as String? ?? '',
        password: json['password'] as String? ?? '',
        mac: json['mac'] as String? ?? '',
        serialNumber: json['serialNumber'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrScanResult &&
          runtimeType == other.runtimeType &&
          ssid == other.ssid &&
          password == other.password &&
          mac == other.mac &&
          serialNumber == other.serialNumber;

  @override
  int get hashCode =>
      ssid.hashCode ^ password.hashCode ^ mac.hashCode ^ serialNumber.hashCode;
}
