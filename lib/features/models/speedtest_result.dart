enum SpeedtestStage {
  idle,
  measuringLatency,
  measuringDownload,
  measuringUpload,
  completed,
  failed,
}

class SpeedtestResult {
  final double pingMs;
  final double jitterMs;
  final double downloadMbps;
  final double uploadMbps;
  final SpeedtestStage stage;
  final String statusMessage;
  final int timestamp;

  const SpeedtestResult({
    this.pingMs = 0.0,
    this.jitterMs = 0.0,
    this.downloadMbps = 0.0,
    this.uploadMbps = 0.0,
    this.stage = SpeedtestStage.idle,
    this.statusMessage = '',
    this.timestamp = 0,
  });

  bool get isRunning =>
      stage == SpeedtestStage.measuringLatency ||
      stage == SpeedtestStage.measuringDownload ||
      stage == SpeedtestStage.measuringUpload;

  SpeedtestResult copyWith({
    double? pingMs,
    double? jitterMs,
    double? downloadMbps,
    double? uploadMbps,
    SpeedtestStage? stage,
    String? statusMessage,
    int? timestamp,
  }) {
    return SpeedtestResult(
      pingMs: pingMs ?? this.pingMs,
      jitterMs: jitterMs ?? this.jitterMs,
      downloadMbps: downloadMbps ?? this.downloadMbps,
      uploadMbps: uploadMbps ?? this.uploadMbps,
      stage: stage ?? this.stage,
      statusMessage: statusMessage ?? this.statusMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pingMs': pingMs,
      'jitterMs': jitterMs,
      'downloadMbps': downloadMbps,
      'uploadMbps': uploadMbps,
      'stage': stage.name,
      'statusMessage': statusMessage,
      'timestamp': timestamp,
    };
  }

  factory SpeedtestResult.fromJson(Map<String, dynamic> json) {
    return SpeedtestResult(
      pingMs: (json['pingMs'] as num?)?.toDouble() ?? 0.0,
      jitterMs: (json['jitterMs'] as num?)?.toDouble() ?? 0.0,
      downloadMbps: (json['downloadMbps'] as num?)?.toDouble() ?? 0.0,
      uploadMbps: (json['uploadMbps'] as num?)?.toDouble() ?? 0.0,
      stage: SpeedtestStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => SpeedtestStage.idle,
      ),
      statusMessage: json['statusMessage'] as String? ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}
