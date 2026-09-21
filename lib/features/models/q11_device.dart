enum NodeRole {
  master,
  satellite;

  String toJson() => name.toUpperCase();
  static NodeRole fromJson(String? value) {
    if (value == null) return NodeRole.master;
    return NodeRole.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => NodeRole.master,
    );
  }
}

enum PatchStatus {
  idle,
  connecting,
  enablingSsh,
  stoppingCloud,
  uploadingScripts,
  configuringPorts,
  completed,
  error;

  static const pending = idle;

  String toJson() => name.toUpperCase();
  static PatchStatus fromJson(String? value) {
    if (value == null) return PatchStatus.idle;
    return PatchStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => PatchStatus.idle,
    );
  }
}

enum BackhaulType {
  wifi5G,
  ethernet;

  static const wifi5g = wifi5G;

  String toJson() => this == BackhaulType.wifi5G ? 'WIFI_5G' : 'ETHERNET';
  static BackhaulType fromJson(String? value) {
    if (value == null) return BackhaulType.wifi5G;
    if (value.toUpperCase() == 'ETHERNET') return BackhaulType.ethernet;
    return BackhaulType.wifi5G;
  }
}

class Q11Device {
  final String id;
  final String name;
  final NodeRole role;
  final String ssidDefault;
  final String wifiPassword;
  final String ipAddress;
  final String mac;
  final String serialNumber;
  final PatchStatus patchStatus;
  final bool isOnline;
  final BackhaulType backhaul;
  final int signalDbm;
  final int lastSeen;

  const Q11Device({
    required this.id,
    this.name = '',
    this.role = NodeRole.master,
    this.ssidDefault = 'q11-xxxx',
    this.wifiPassword = '',
    this.ipAddress = '192.168.1.1',
    this.mac = '',
    this.serialNumber = '',
    this.patchStatus = PatchStatus.idle,
    this.isOnline = false,
    this.backhaul = BackhaulType.wifi5G,
    this.signalDbm = -55,
    this.lastSeen = 0,
  });

  Q11Device copy({
    String? id,
    String? name,
    NodeRole? role,
    String? ssidDefault,
    String? wifiPassword,
    String? ipAddress,
    String? mac,
    String? macAddress,
    String? serialNumber,
    PatchStatus? patchStatus,
    bool? isOnline,
    BackhaulType? backhaul,
    int? signalDbm,
    int? lastSeen,
  }) =>
      copyWith(
        id: id,
        name: name,
        role: role,
        ssidDefault: ssidDefault,
        wifiPassword: wifiPassword,
        ipAddress: ipAddress,
        mac: macAddress ?? mac,
        serialNumber: serialNumber,
        patchStatus: patchStatus,
        isOnline: isOnline,
        backhaul: backhaul,
        signalDbm: signalDbm,
        lastSeen: lastSeen,
      );

  Q11Device copyWith({
    String? id,
    String? name,
    NodeRole? role,
    String? ssidDefault,
    String? wifiPassword,
    String? ipAddress,
    String? mac,
    String? macAddress,
    String? serialNumber,
    PatchStatus? patchStatus,
    bool? isOnline,
    BackhaulType? backhaul,
    int? signalDbm,
    int? lastSeen,
  }) {
    return Q11Device(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      ssidDefault: ssidDefault ?? this.ssidDefault,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      ipAddress: ipAddress ?? this.ipAddress,
      mac: macAddress ?? mac ?? this.mac,
      serialNumber: serialNumber ?? this.serialNumber,
      patchStatus: patchStatus ?? this.patchStatus,
      isOnline: isOnline ?? this.isOnline,
      backhaul: backhaul ?? this.backhaul,
      signalDbm: signalDbm ?? this.signalDbm,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.toJson(),
      'ssidDefault': ssidDefault,
      'wifiPassword': wifiPassword,
      'ipAddress': ipAddress,
      'mac': mac,
      'serialNumber': serialNumber,
      'patchStatus': patchStatus.toJson(),
      'isOnline': isOnline,
      'backhaul': backhaul.toJson(),
      'signalDbm': signalDbm,
      'lastSeen': lastSeen == 0 ? DateTime.now().millisecondsSinceEpoch : lastSeen,
    };
  }

  factory Q11Device.fromJson(Map<String, dynamic> json) {
    return Q11Device(
      id: json['id'] as String? ?? 'node-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Q11 Node',
      role: NodeRole.fromJson(json['role'] as String?),
      ssidDefault: json['ssidDefault'] as String? ?? 'q11-xxxx',
      wifiPassword: json['wifiPassword'] as String? ?? '',
      ipAddress: json['ipAddress'] as String? ?? '192.168.1.1',
      mac: json['mac'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      patchStatus: PatchStatus.fromJson(json['patchStatus'] as String?),
      isOnline: json['isOnline'] as bool? ?? false,
      backhaul: BackhaulType.fromJson(json['backhaul'] as String?),
      signalDbm: (json['signalDbm'] as num?)?.toInt() ?? -55,
      lastSeen: (json['lastSeen'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Q11Device &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          role == other.role &&
          ssidDefault == other.ssidDefault &&
          wifiPassword == other.wifiPassword &&
          ipAddress == other.ipAddress &&
          mac == other.mac &&
          serialNumber == other.serialNumber &&
          patchStatus == other.patchStatus &&
          isOnline == other.isOnline &&
          backhaul == other.backhaul &&
          signalDbm == other.signalDbm;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      role.hashCode ^
      ssidDefault.hashCode ^
      wifiPassword.hashCode ^
      ipAddress.hashCode ^
      mac.hashCode ^
      serialNumber.hashCode ^
      patchStatus.hashCode ^
      isOnline.hashCode ^
      backhaul.hashCode ^
      signalDbm.hashCode;
}
