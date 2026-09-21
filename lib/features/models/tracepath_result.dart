class TraceHop {
  final int hopNumber;
  final String ip;
  final double rttMs;

  const TraceHop({
    required this.hopNumber,
    required this.ip,
    required this.rttMs,
  });

  Map<String, dynamic> toJson() => {
        'hopNumber': hopNumber,
        'ip': ip,
        'rttMs': rttMs,
      };

  factory TraceHop.fromJson(Map<String, dynamic> json) => TraceHop(
        hopNumber: (json['hopNumber'] as num?)?.toInt() ?? 1,
        ip: json['ip'] as String? ?? '*',
        rttMs: (json['rttMs'] as num?)?.toDouble() ?? 0.0,
      );
}

class TracepathResult {
  final String targetIp;
  final List<TraceHop> hops;
  final String rawOutput;

  const TracepathResult({
    required this.targetIp,
    required this.hops,
    required this.rawOutput,
  });

  Map<String, dynamic> toJson() => {
        'targetIp': targetIp,
        'hops': hops.map((e) => e.toJson()).toList(),
        'rawOutput': rawOutput,
      };

  factory TracepathResult.fromJson(Map<String, dynamic> json) => TracepathResult(
        targetIp: json['targetIp'] as String? ?? '',
        hops: (json['hops'] as List<dynamic>?)
                ?.map((e) => TraceHop.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        rawOutput: json['rawOutput'] as String? ?? '',
      );
}
