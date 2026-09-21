import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../patcher/domain/q11_patch_engine.dart';
import '../../../core/providers/app_providers.dart';

class DiagnosticsState {
  final List<SubnetScanResult> subnetResults;
  final bool isScanning;
  final String scanProgress;
  final bool isRunningPing;
  final bool isRunningTrace;
  final String consoleOutput;
  final List<DhcpClient> dhcpClients;
  final bool isRefreshingClients;
  final Map<String, DeviceTelemetry> deviceTelemetry;
  final SpeedtestResult speedtestResult;
  final String? localConnectedNodeIp;
  final Set<String> flashingNodeIps;

  const DiagnosticsState({
    this.subnetResults = const [],
    this.isScanning = false,
    this.scanProgress = '',
    this.isRunningPing = false,
    this.isRunningTrace = false,
    this.consoleOutput = '',
    this.dhcpClients = const [],
    this.isRefreshingClients = false,
    this.deviceTelemetry = const {},
    this.speedtestResult = const SpeedtestResult(),
    this.localConnectedNodeIp,
    this.flashingNodeIps = const {},
  });

  DiagnosticsState copyWith({
    List<SubnetScanResult>? subnetResults,
    bool? isScanning,
    String? scanProgress,
    bool? isRunningPing,
    bool? isRunningTrace,
    String? consoleOutput,
    List<DhcpClient>? dhcpClients,
    bool? isRefreshingClients,
    Map<String, DeviceTelemetry>? deviceTelemetry,
    SpeedtestResult? speedtestResult,
    String? localConnectedNodeIp,
    Set<String>? flashingNodeIps,
  }) {
    return DiagnosticsState(
      subnetResults: subnetResults ?? this.subnetResults,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      isRunningPing: isRunningPing ?? this.isRunningPing,
      isRunningTrace: isRunningTrace ?? this.isRunningTrace,
      consoleOutput: consoleOutput ?? this.consoleOutput,
      dhcpClients: dhcpClients ?? this.dhcpClients,
      isRefreshingClients: isRefreshingClients ?? this.isRefreshingClients,
      deviceTelemetry: deviceTelemetry ?? this.deviceTelemetry,
      speedtestResult: speedtestResult ?? this.speedtestResult,
      localConnectedNodeIp: localConnectedNodeIp ?? this.localConnectedNodeIp,
      flashingNodeIps: flashingNodeIps ?? this.flashingNodeIps,
    );
  }
}

class DiagnosticsController extends StateNotifier<DiagnosticsState> {
  final Ref _ref;

  DiagnosticsController(this._ref) : super(const DiagnosticsState());

  Future<void> scanSubnet(String basePrefix) async {
    final patchEngine = _ref.read(patchEngineProvider);
    state = state.copyWith(
      isScanning: true,
      subnetResults: [],
      scanProgress: '0 / 254',
    );

    try {
      final results = await patchEngine.scanSubnet(
        baseIpPrefix: basePrefix,
        onProgress: (curr, total) {
          state = state.copyWith(scanProgress: '$curr / $total');
        },
      );

      final customNames = _ref.read(customDeviceNamesProvider);
      final enriched = results.map((r) {
        final savedName = customNames[r.macAddress.toLowerCase()] ??
            customNames[r.ip] ??
            '';
        return r.copyWith(customName: savedName);
      }).toList();

      state = state.copyWith(
        isScanning: false,
        subnetResults: enriched,
      );

      // Auto check connected node if nodes available
      await identifyConnectedNode();
    } catch (_) {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<void> updateDeviceCustomName(String identifier, String newName, {String? macAddress}) async {
    final storage = _ref.read(localStorageProvider);
    if (macAddress != null && macAddress.isNotEmpty) {
      await storage.setDeviceName(macAddress, newName);
    }
    await storage.setDeviceName(identifier, newName);
    _ref.read(customDeviceNamesProvider.notifier).refreshFromStorage();

    // Also update current state in-place
    final updatedList = state.subnetResults.map((r) {
      if (r.ip == identifier || (macAddress != null && r.macAddress == macAddress)) {
        return r.copyWith(customName: newName.trim());
      }
      return r;
    }).toList();

    state = state.copyWith(subnetResults: updatedList);
  }

  Future<void> runPing(String targetIp) async {
    final patchEngine = _ref.read(patchEngineProvider);
    state = state.copyWith(
      isRunningPing: true,
      consoleOutput: 'Pinging $targetIp (4 packets)...',
    );

    try {
      final res = await patchEngine.pingTarget(targetIp);
      state = state.copyWith(
        isRunningPing: false,
        consoleOutput: res.rawOutput,
      );
    } catch (e) {
      state = state.copyWith(
        isRunningPing: false,
        consoleOutput: 'Ping failed: $e',
      );
    }
  }

  Future<void> runTracepath(String targetIp) async {
    final patchEngine = _ref.read(patchEngineProvider);
    state = state.copyWith(
      isRunningTrace: true,
      consoleOutput: 'Tracing route to $targetIp (max 12 hops)...',
    );

    try {
      final res = await patchEngine.tracepathTarget(
        targetIp,
        onHopDiscovered: (hop) {
          state = state.copyWith(
            consoleOutput: 'Hop ${hop.hopNumber}: ${hop.ip} (${hop.rttMs} ms)',
          );
        },
      );
      state = state.copyWith(
        isRunningTrace: false,
        consoleOutput: res.rawOutput,
      );
    } catch (e) {
      state = state.copyWith(
        isRunningTrace: false,
        consoleOutput: 'Tracepath failed: $e',
      );
    }
  }

  Future<void> refreshClients(String masterIp, String wifiPassword) async {
    final patchEngine = _ref.read(patchEngineProvider);
    state = state.copyWith(isRefreshingClients: true);

    try {
      final isAlive = await patchEngine.testConnection(masterIp);
      final master = _ref.read(masterNodeProvider);
      await _ref.read(masterNodeProvider.notifier).update(master.copy(isOnline: isAlive));

      final clients = await patchEngine.fetchDhcpClients(masterIp, wifiPassword);
      state = state.copyWith(
        isRefreshingClients: false,
        dhcpClients: clients,
      );

      // Refresh connected node detection
      await identifyConnectedNode();
    } catch (_) {
      state = state.copyWith(isRefreshingClients: false);
    }
  }

  /// Flash device LED for 15 seconds to locate unit
  Future<bool> flashDeviceLed(String ip, String wifiPassword) async {
    final patchEngine = _ref.read(patchEngineProvider);
    final active = Set<String>.from(state.flashingNodeIps)..add(ip);
    state = state.copyWith(flashingNodeIps: active);

    try {
      final success = await patchEngine.flashDeviceLed(ip, wifiPassword, durationSeconds: 15);
      Future.delayed(const Duration(seconds: 15), () {
        final current = Set<String>.from(state.flashingNodeIps)..remove(ip);
        state = state.copyWith(flashingNodeIps: current);
      });
      return success;
    } catch (e) {
      final current = Set<String>.from(state.flashingNodeIps)..remove(ip);
      state = state.copyWith(flashingNodeIps: current);
      return false;
    }
  }

  /// Fetch important statistics and configured SSIDs for a device
  Future<DeviceTelemetry?> fetchDeviceStats(String ip, String wifiPassword) async {
    final patchEngine = _ref.read(patchEngineProvider);
    try {
      final stats = await patchEngine.fetchDeviceStatistics(ip, wifiPassword);
      final updatedMap = Map<String, DeviceTelemetry>.from(state.deviceTelemetry);
      updatedMap[ip] = stats;
      state = state.copyWith(deviceTelemetry: updatedMap);
      return stats;
    } catch (_) {
      return null;
    }
  }

  /// Identify which mesh node the user's host machine is directly connected to
  Future<String?> identifyConnectedNode() async {
    final master = _ref.read(masterNodeProvider);
    final satellites = _ref.read(satellitesProvider);
    final allNodes = [master, ...satellites];

    final connectedIp = await Q11PatchEngine.identifyLocalConnectedNode(allNodes);
    state = state.copyWith(localConnectedNodeIp: connectedIp);
    return connectedIp;
  }

  /// Run network speedtest
  Future<SpeedtestResult> runSpeedTest() async {
    final patchEngine = _ref.read(patchEngineProvider);
    state = state.copyWith(
      speedtestResult: const SpeedtestResult(
        stage: SpeedtestStage.measuringLatency,
        statusMessage: 'Starting network speed test...',
      ),
    );

    final finalResult = await patchEngine.runSpeedTest(
      onProgress: (current) {
        state = state.copyWith(speedtestResult: current);
      },
    );

    state = state.copyWith(speedtestResult: finalResult);
    return finalResult;
  }

  /// Full backup of device OpenWrt `/etc/config`
  Future<String?> backupDeviceConfig(String ip, String wifiPassword) async {
    final patchEngine = _ref.read(patchEngineProvider);
    try {
      return await patchEngine.backupDeviceConfig(ip, wifiPassword);
    } catch (_) {
      return null;
    }
  }

  /// Restore configuration tarball to device over SSH
  Future<bool> restoreDeviceConfig(String ip, String wifiPassword, String configBase64) async {
    final patchEngine = _ref.read(patchEngineProvider);
    try {
      return await patchEngine.restoreDeviceConfig(ip, wifiPassword, configBase64);
    } catch (_) {
      return false;
    }
  }
}

final diagnosticsProvider =
    StateNotifierProvider<DiagnosticsController, DiagnosticsState>((ref) {
  return DiagnosticsController(ref);
});
