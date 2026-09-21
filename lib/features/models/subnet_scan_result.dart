class SubnetScanResult {
  final String ip;
  final bool isQ11Device;
  final List<int> portsOpen;
  final int rttMs;
  final String hostname;
  final String macAddress;
  final String role;
  final bool isMaster;
  final String customName;

  const SubnetScanResult({
    required this.ip,
    required this.isQ11Device,
    required this.portsOpen,
    required this.rttMs,
    this.hostname = '',
    this.macAddress = '',
    this.role = '',
    this.isMaster = false,
    this.customName = '',
  });

  SubnetScanResult copyWith({
    String? ip,
    bool? isQ11Device,
    List<int>? portsOpen,
    int? rttMs,
    String? hostname,
    String? macAddress,
    String? role,
    bool? isMaster,
    String? customName,
  }) =>
      SubnetScanResult(
        ip: ip ?? this.ip,
        isQ11Device: isQ11Device ?? this.isQ11Device,
        portsOpen: portsOpen ?? this.portsOpen,
        rttMs: rttMs ?? this.rttMs,
        hostname: hostname ?? this.hostname,
        macAddress: macAddress ?? this.macAddress,
        role: role ?? this.role,
        isMaster: isMaster ?? this.isMaster,
        customName: customName ?? this.customName,
      );

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'isQ11Device': isQ11Device,
        'portsOpen': portsOpen,
        'rttMs': rttMs,
        'hostname': hostname,
        'macAddress': macAddress,
        'role': role,
        'isMaster': isMaster,
        'customName': customName,
      };

  factory SubnetScanResult.fromJson(Map<String, dynamic> json) => SubnetScanResult(
        ip: json['ip'] as String? ?? '',
        isQ11Device: json['isQ11Device'] as bool? ?? false,
        portsOpen: (json['portsOpen'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
        rttMs: (json['rttMs'] as num?)?.toInt() ?? 0,
        hostname: json['hostname'] as String? ?? '',
        macAddress: json['macAddress'] as String? ?? '',
        role: json['role'] as String? ?? '',
        isMaster: json['isMaster'] as bool? ?? false,
        customName: json['customName'] as String? ?? '',
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
