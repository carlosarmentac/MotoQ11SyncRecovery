class PingResult {
  final String targetIp;
  final int packetsSent;
  final int packetsReceived;
  final double lossPercent;
  final double minRttMs;
  final double avgRttMs;
  final double maxRttMs;
  final String rawOutput;

  const PingResult({
    required this.targetIp,
    required this.packetsSent,
    required this.packetsReceived,
    required this.lossPercent,
    required this.minRttMs,
    required this.avgRttMs,
    required this.maxRttMs,
    required this.rawOutput,
  });

  bool get isSuccess => packetsReceived > 0;

  Map<String, dynamic> toJson() => {
        'targetIp': targetIp,
        'packetsSent': packetsSent,
        'packetsReceived': packetsReceived,
        'lossPercent': lossPercent,
        'minRttMs': minRttMs,
        'avgRttMs': avgRttMs,
        'maxRttMs': maxRttMs,
        'rawOutput': rawOutput,
      };

  factory PingResult.fromJson(Map<String, dynamic> json) => PingResult(
        targetIp: json['targetIp'] as String? ?? '',
        packetsSent: (json['packetsSent'] as num?)?.toInt() ?? 0,
        packetsReceived: (json['packetsReceived'] as num?)?.toInt() ?? 0,
        lossPercent: (json['lossPercent'] as num?)?.toDouble() ?? 0.0,
        minRttMs: (json['minRttMs'] as num?)?.toDouble() ?? 0.0,
        avgRttMs: (json['avgRttMs'] as num?)?.toDouble() ?? 0.0,
        maxRttMs: (json['maxRttMs'] as num?)?.toDouble() ?? 0.0,
        rawOutput: json['rawOutput'] as String? ?? '',
      );
}
