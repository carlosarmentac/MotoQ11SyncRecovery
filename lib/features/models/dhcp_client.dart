class DhcpClient {
  final String ip;
  final String mac;
  final String name;
  final String leaseTime;

  const DhcpClient({
    required this.ip,
    required this.mac,
    required this.name,
    this.leaseTime = '',
  });

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'mac': mac,
        'name': name,
        'leaseTime': leaseTime,
      };

  factory DhcpClient.fromJson(Map<String, dynamic> json) => DhcpClient(
        ip: json['ip'] as String? ?? '',
        mac: json['mac'] as String? ?? '',
        name: json['name'] as String? ?? '',
        leaseTime: json['leaseTime'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DhcpClient &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          mac == other.mac &&
          name == other.name;

  @override
  int get hashCode => ip.hashCode ^ mac.hashCode ^ name.hashCode;
}
