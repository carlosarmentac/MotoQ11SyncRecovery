class WifiMeshConfig {
  final String home24Ssid;
  final String home24Pass;
  final String home5Ssid;
  final String home5Pass;
  final String guest24Ssid;
  final String guest24Pass;
  final String guest5Ssid;
  final String guest5Pass;

  const WifiMeshConfig({
    this.home24Ssid = 'MyHome_2.4G',
    this.home24Pass = 'SecurePass2026',
    this.home5Ssid = 'MyHome_5G',
    this.home5Pass = 'SecurePass2026',
    this.guest24Ssid = 'MyHome_Guest_2.4G',
    this.guest24Pass = 'GuestPass2026',
    this.guest5Ssid = 'MyHome_Guest_5G',
    this.guest5Pass = 'GuestPass2026',
  });

  WifiMeshConfig copyWith({
    String? home24Ssid,
    String? home24Pass,
    String? home5Ssid,
    String? home5Pass,
    String? guest24Ssid,
    String? guest24Pass,
    String? guest5Ssid,
    String? guest5Pass,
  }) {
    return WifiMeshConfig(
      home24Ssid: home24Ssid ?? this.home24Ssid,
      home24Pass: home24Pass ?? this.home24Pass,
      home5Ssid: home5Ssid ?? this.home5Ssid,
      home5Pass: home5Pass ?? this.home5Pass,
      guest24Ssid: guest24Ssid ?? this.guest24Ssid,
      guest24Pass: guest24Pass ?? this.guest24Pass,
      guest5Ssid: guest5Ssid ?? this.guest5Ssid,
      guest5Pass: guest5Pass ?? this.guest5Pass,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'home24Ssid': home24Ssid,
      'home24Pass': home24Pass,
      'home5Ssid': home5Ssid,
      'home5Pass': home5Pass,
      'guest24Ssid': guest24Ssid,
      'guest24Pass': guest24Pass,
      'guest5Ssid': guest5Ssid,
      'guest5Pass': guest5Pass,
    };
  }

  factory WifiMeshConfig.fromJson(Map<String, dynamic> json) {
    return WifiMeshConfig(
      home24Ssid: json['home24Ssid'] as String? ?? 'MyHome_2.4G',
      home24Pass: json['home24Pass'] as String? ?? 'SecurePass2026',
      home5Ssid: json['home5Ssid'] as String? ?? 'MyHome_5G',
      home5Pass: json['home5Pass'] as String? ?? 'SecurePass2026',
      guest24Ssid: json['guest24Ssid'] as String? ?? 'MyHome_Guest_2.4G',
      guest24Pass: json['guest24Pass'] as String? ?? 'GuestPass2026',
      guest5Ssid: json['guest5Ssid'] as String? ?? 'MyHome_Guest_5G',
      guest5Pass: json['guest5Pass'] as String? ?? 'GuestPass2026',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WifiMeshConfig &&
          runtimeType == other.runtimeType &&
          home24Ssid == other.home24Ssid &&
          home24Pass == other.home24Pass &&
          home5Ssid == other.home5Ssid &&
          home5Pass == other.home5Pass &&
          guest24Ssid == other.guest24Ssid &&
          guest24Pass == other.guest24Pass &&
          guest5Ssid == other.guest5Ssid &&
          guest5Pass == other.guest5Pass;

  @override
  int get hashCode =>
      home24Ssid.hashCode ^
      home24Pass.hashCode ^
      home5Ssid.hashCode ^
      home5Pass.hashCode ^
      guest24Ssid.hashCode ^
      guest24Pass.hashCode ^
      guest5Ssid.hashCode ^
      guest5Pass.hashCode;
}
