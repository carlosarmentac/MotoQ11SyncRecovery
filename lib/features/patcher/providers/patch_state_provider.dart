import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../../core/providers/app_providers.dart';

class TestSuiteState {
  final bool isRunning;
  final bool? internetOk;
  final bool? servicesOk;
  final bool? satellitesOk;
  final int? clientsCount;
  final String? summary;

  const TestSuiteState({
    this.isRunning = false,
    this.internetOk,
    this.servicesOk,
    this.satellitesOk,
    this.clientsCount,
    this.summary,
  });

  TestSuiteState copyWith({
    bool? isRunning,
    bool? internetOk,
    bool? servicesOk,
    bool? satellitesOk,
    int? clientsCount,
    String? summary,
    bool clearResults = false,
  }) {
    if (clearResults) {
      return TestSuiteState(isRunning: isRunning ?? this.isRunning);
    }
    return TestSuiteState(
      isRunning: isRunning ?? this.isRunning,
      internetOk: internetOk ?? this.internetOk,
      servicesOk: servicesOk ?? this.servicesOk,
      satellitesOk: satellitesOk ?? this.satellitesOk,
      clientsCount: clientsCount ?? this.clientsCount,
      summary: summary ?? this.summary,
    );
  }
}

class PatchingState {
  final bool isPatching;
  final String log;
  final bool? lastSuccess;

  const PatchingState({
    this.isPatching = false,
    this.log = 'Ready to begin...',
    this.lastSuccess,
  });

  PatchingState copyWith({
    bool? isPatching,
    String? log,
    bool? lastSuccess,
  }) {
    return PatchingState(
      isPatching: isPatching ?? this.isPatching,
      log: log ?? this.log,
      lastSuccess: lastSuccess ?? this.lastSuccess,
    );
  }
}

class PatchController extends StateNotifier<PatchingState> {
  final Ref _ref;

  PatchController(this._ref) : super(const PatchingState());

  Future<bool> flashMaster() async {
    final patchEngine = _ref.read(patchEngineProvider);
    final master = _ref.read(masterNodeProvider);
    final masterNotifier = _ref.read(masterNodeProvider.notifier);

    state = state.copyWith(isPatching: true, log: 'Initiating unlock on ${master.ipAddress}...');
    await masterNotifier.update(master.copy(patchStatus: PatchStatus.connecting));

    try {
      // 1. Trigger CGI SSH
      state = state.copyWith(log: 'Step 1/3: Triggering CGI SSH enablement...');
      await masterNotifier.update(master.copy(patchStatus: PatchStatus.enablingSsh));
      await patchEngine.enableSsh(master.ipAddress, master.wifiPassword);

      // 2. Deploy Patch over SSH
      state = state.copyWith(log: 'Step 2/3: Deploying OpenWrt scripts via SSH...');
      await masterNotifier.update(master.copy(patchStatus: PatchStatus.uploadingScripts));
      await patchEngine.deployPatch(
        master.ipAddress,
        master.wifiPassword,
        onProgress: (p) => state = state.copyWith(log: p),
      );

      // 3. Port Verification
      state = state.copyWith(log: 'Step 3/3: Verifying required open ports...');
      await masterNotifier.update(master.copy(patchStatus: PatchStatus.configuringPorts));
      final verified = await patchEngine.verifyPatchSuccess(master.ipAddress);

      if (verified) {
        state = state.copyWith(
          isPatching: false,
          log: 'Master node successfully patched & verified! Ports 22, 80/8080 active.',
          lastSuccess: true,
        );
        await masterNotifier.update(master.copy(patchStatus: PatchStatus.completed, isOnline: true));
        return true;
      } else {
        state = state.copyWith(
          isPatching: false,
          log: 'Verification failed: Required ports (22, 80, 8080) did not respond.',
          lastSuccess: false,
        );
        await masterNotifier.update(master.copy(patchStatus: PatchStatus.error, isOnline: false));
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isPatching: false,
        log: 'Flashing error: $e',
        lastSuccess: false,
      );
      await masterNotifier.update(master.copy(patchStatus: PatchStatus.error, isOnline: false));
      return false;
    }
  }

  Future<bool> flashSatellite(int index) async {
    final patchEngine = _ref.read(patchEngineProvider);
    final satellites = _ref.read(satellitesProvider);
    final satellitesNotifier = _ref.read(satellitesProvider.notifier);
    final master = _ref.read(masterNodeProvider);
    final wifi = _ref.read(wifiMeshConfigProvider);

    final sat = (index < satellites.length)
        ? satellites[index]
        : Q11Device(
            id: 'sat-${index + 1}',
            name: 'Satellite ${index + 1}',
            role: NodeRole.satellite,
            ipAddress: '192.168.1.${20 + index}',
            ssidDefault: 'q11-sat${index + 1}',
            wifiPassword: master.wifiPassword,
          );

    state = state.copyWith(
      isPatching: true,
      log: 'Satellite ${index + 1}: Enabling SSH on ${sat.ipAddress}...',
    );

    try {
      await patchEngine.enableSsh(sat.ipAddress, sat.wifiPassword);
      state = state.copyWith(log: 'Satellite ${index + 1}: Deploying patch...');

      await patchEngine.deployPatch(
        sat.ipAddress,
        sat.wifiPassword,
        onProgress: (p) => state = state.copyWith(log: 'Satellite ${index + 1}: $p'),
      );

      state = state.copyWith(log: 'Satellite ${index + 1}: Configuring WET bridge link...');
      await patchEngine.configureSatelliteBridge(
        ip: sat.ipAddress,
        password: sat.wifiPassword,
        masterSsid: wifi.home5Ssid,
        masterKey: wifi.home5Pass,
        newLanIp: sat.ipAddress,
      );

      final updatedSat = sat.copy(patchStatus: PatchStatus.completed, isOnline: true);
      await satellitesNotifier.saveSatellite(updatedSat);

      state = state.copyWith(
        isPatching: false,
        log: 'Satellite ${index + 1} patched and bridged to mesh!',
        lastSuccess: true,
      );
      return true;
    } catch (e) {
      final errorSat = sat.copy(patchStatus: PatchStatus.error, isOnline: false);
      await satellitesNotifier.saveSatellite(errorSat);
      state = state.copyWith(
        isPatching: false,
        log: 'Satellite ${index + 1} flashing failed: $e',
        lastSuccess: false,
      );
      return false;
    }
  }
}

final patchStateProvider =
    StateNotifierProvider<PatchController, PatchingState>((ref) {
  return PatchController(ref);
});

// ─── Step 5 Test Suite Controller ─────────────────────────────────────────────

class TestSuiteController extends StateNotifier<TestSuiteState> {
  final Ref _ref;

  TestSuiteController(this._ref) : super(const TestSuiteState());

  Future<void> runAllTests() async {
    final patchEngine = _ref.read(patchEngineProvider);
    final master = _ref.read(masterNodeProvider);
    final kitSize = _ref.read(kitSizeProvider);
    final satellites = _ref.read(satellitesProvider);

    state = state.copyWith(isRunning: true, clearResults: true);

    // 1. Router local services check
    final servicesOk = await patchEngine.verifyPatchSuccess(master.ipAddress);

    // 2. Internet uplink check (Ping 8.8.8.8)
    final pingRes = await patchEngine.pingTarget('8.8.8.8', count: 3);
    final internetOk = pingRes.packetsReceived > 0;

    // 3. Satellite reachability check (if multi-node)
    bool satellitesOk = true;
    if (kitSize > 1) {
      final needed = kitSize - 1;
      int reachable = 0;
      for (var i = 0; i < needed; i++) {
        final satIp = (i < satellites.length)
            ? satellites[i].ipAddress
            : '192.168.1.${20 + i}';
        final isAlive = await patchEngine.testConnection(satIp);
        if (isAlive) reachable++;
      }
      satellitesOk = reachable >= needed;
    }

    // 4. Client count
    final clients =
        await patchEngine.fetchDhcpClients(master.ipAddress, master.wifiPassword);

    final allPassed = servicesOk && internetOk && satellitesOk;
    final summary = allPassed
        ? 'All diagnostic tests passed! Mesh network is fully operational.'
        : 'Some tests reported warnings or unreachable services.';

    state = TestSuiteState(
      isRunning: false,
      servicesOk: servicesOk,
      internetOk: internetOk,
      satellitesOk: satellitesOk,
      clientsCount: clients.length,
      summary: summary,
    );
  }

  Future<void> runSuite() => runAllTests();
}

final testSuiteProvider =
    StateNotifierProvider<TestSuiteController, TestSuiteState>((ref) {
  return TestSuiteController(ref);
});

final patchControllerProvider = patchStateProvider;
final testSuiteControllerProvider = testSuiteProvider;
