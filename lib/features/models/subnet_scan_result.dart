class SubnetScanResult {
  final String ip;
  final bool isQ11Device;
  final List<int> portsOpen;
  final int rttMs;
  final String hostname;

  const SubnetScanResult({
    required this.ip,
    required this.isQ11Device,
    required this.portsOpen,
    required this.rttMs,
    this.hostname = '',
  });

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'isQ11Device': isQ11Device,
        'portsOpen': portsOpen,
        'rttMs': rttMs,
        'hostname': hostname,
      };

  factory SubnetScanResult.fromJson(Map<String, dynamic> json) => SubnetScanResult(
        ip: json['ip'] as String? ?? '',
        isQ11Device: json['isQ11Device'] as bool? ?? false,
        portsOpen: (json['portsOpen'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
        rttMs: (json['rttMs'] as num?)?.toInt() ?? 0,
        hostname: json['hostname'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubnetScanResult &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          isQ11Device == other.isQ11Device &&
          rttMs == other.rttMs;

  @override
  int get hashCode => ip.hashCode ^ isQ11Device.hashCode ^ rttMs.hashCode;
}
