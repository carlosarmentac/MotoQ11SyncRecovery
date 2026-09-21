class DeviceTelemetry {
  final String ip;
  final String uptime;
  final double cpuLoad;
  final int totalMemMb;
  final int freeMemMb;
  final int usedMemMb;
  final List<String> configuredSsids;
  final String kernelVersion;
  final String boardName;
  final int timestamp;

  const DeviceTelemetry({
    required this.ip,
    this.uptime = 'Unknown',
    this.cpuLoad = 0.0,
    this.totalMemMb = 512,
    this.freeMemMb = 0,
    this.usedMemMb = 0,
    this.configuredSsids = const [],
    this.kernelVersion = '',
    this.boardName = 'Motorola Q11 (MH760x)',
    this.timestamp = 0,
  });

  double get memoryUsagePercent {
    if (totalMemMb <= 0) return 0.0;
    return ((usedMemMb / totalMemMb) * 100).clamp(0.0, 100.0);
  }

  DeviceTelemetry copyWith({
    String? ip,
    String? uptime,
    double? cpuLoad,
    int? totalMemMb,
    int? freeMemMb,
    int? usedMemMb,
    List<String>? configuredSsids,
    String? kernelVersion,
    String? boardName,
    int? timestamp,
  }) {
    return DeviceTelemetry(
      ip: ip ?? this.ip,
      uptime: uptime ?? this.uptime,
      cpuLoad: cpuLoad ?? this.cpuLoad,
      totalMemMb: totalMemMb ?? this.totalMemMb,
      freeMemMb: freeMemMb ?? this.freeMemMb,
      usedMemMb: usedMemMb ?? this.usedMemMb,
      configuredSsids: configuredSsids ?? this.configuredSsids,
      kernelVersion: kernelVersion ?? this.kernelVersion,
      boardName: boardName ?? this.boardName,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'uptime': uptime,
      'cpuLoad': cpuLoad,
      'totalMemMb': totalMemMb,
      'freeMemMb': freeMemMb,
      'usedMemMb': usedMemMb,
      'configuredSsids': configuredSsids,
      'kernelVersion': kernelVersion,
      'boardName': boardName,
      'timestamp': timestamp,
    };
  }

  factory DeviceTelemetry.fromJson(Map<String, dynamic> json) {
    return DeviceTelemetry(
      ip: json['ip'] as String? ?? '',
      uptime: json['uptime'] as String? ?? 'Unknown',
      cpuLoad: (json['cpuLoad'] as num?)?.toDouble() ?? 0.0,
      totalMemMb: (json['totalMemMb'] as num?)?.toInt() ?? 512,
      freeMemMb: (json['freeMemMb'] as num?)?.toInt() ?? 0,
      usedMemMb: (json['usedMemMb'] as num?)?.toInt() ?? 0,
      configuredSsids: (json['configuredSsids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      kernelVersion: json['kernelVersion'] as String? ?? '',
      boardName: json['boardName'] as String? ?? 'Motorola Q11 (MH760x)',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}
