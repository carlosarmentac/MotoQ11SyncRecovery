import 'package:flutter_test/flutter_test.dart';
import 'package:motoq11_saver/features/models/models.dart';

void main() {
  group('DeviceTelemetry Model', () {
    test('serializes and deserializes correctly', () {
      final telemetry = DeviceTelemetry(
        ip: '10.10.11.1',
        uptime: '2 days, 4 hours',
        cpuLoad: 0.45,
        totalMemMb: 512,
        freeMemMb: 256,
        usedMemMb: 256,
        configuredSsids: ['Home_24G', 'Home_5G'],
        kernelVersion: '5.4.188',
        boardName: 'Motorola Q11',
        timestamp: 1690000000000,
      );

      final json = telemetry.toJson();
      final fromJson = DeviceTelemetry.fromJson(json);

      expect(fromJson.ip, equals('10.10.11.1'));
      expect(fromJson.uptime, equals('2 days, 4 hours'));
      expect(fromJson.cpuLoad, equals(0.45));
      expect(fromJson.totalMemMb, equals(512));
      expect(fromJson.freeMemMb, equals(256));
      expect(fromJson.usedMemMb, equals(256));
      expect(fromJson.configuredSsids, equals(['Home_24G', 'Home_5G']));
      expect(fromJson.memoryUsagePercent, closeTo(50.0, 0.1));
    });

    test('calculates memory usage percent correctly when total is zero', () {
      const emptyTelemetry = DeviceTelemetry(ip: '10.10.11.2');
      expect(emptyTelemetry.memoryUsagePercent, equals(0.0));
    });
  });

  group('SpeedtestResult Model', () {
    test('serializes and parses speedtest results with all stages', () {
      const speedtest = SpeedtestResult(
        pingMs: 14.5,
        jitterMs: 1.2,
        downloadMbps: 215.4,
        uploadMbps: 45.8,
        stage: SpeedtestStage.completed,
        statusMessage: 'Speed test completed successfully',
        timestamp: 1690000000000,
      );

      final json = speedtest.toJson();
      final fromJson = SpeedtestResult.fromJson(json);

      expect(fromJson.pingMs, equals(14.5));
      expect(fromJson.jitterMs, equals(1.2));
      expect(fromJson.downloadMbps, equals(215.4));
      expect(fromJson.uploadMbps, equals(45.8));
      expect(fromJson.stage, equals(SpeedtestStage.completed));
      expect(fromJson.statusMessage, equals('Speed test completed successfully'));
    });
  });
}
