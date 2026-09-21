import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
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

  const DiagnosticsState({
    this.subnetResults = const [],
    this.isScanning = false,
    this.scanProgress = '',
    this.isRunningPing = false,
    this.isRunningTrace = false,
    this.consoleOutput = '',
    this.dhcpClients = const [],
    this.isRefreshingClients = false,
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
    } catch (_) {
      state = state.copyWith(isRefreshingClients: false);
    }
  }
}

final diagnosticsProvider =
    StateNotifierProvider<DiagnosticsController, DiagnosticsState>((ref) {
  return DiagnosticsController(ref);
});
