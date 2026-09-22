import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/models/models.dart';
import '../../features/patcher/domain/q11_patch_engine.dart';
import '../storage/q11_local_storage.dart';

/// Must be overridden in ProviderScope at app initialization
final localStorageProvider = Provider<Q11LocalStorage>((ref) {
  throw UnimplementedError('localStorageProvider must be initialized');
});

final patchEngineProvider = Provider<Q11PatchEngine>((ref) {
  return Q11PatchEngine();
});

// ─── Language Provider ────────────────────────────────────────────────────────

class LanguageNotifier extends StateNotifier<String> {
  final Q11LocalStorage _storage;
  LanguageNotifier(this._storage) : super(_storage.getLanguage());

  Future<void> setLanguage(String lang) async {
    state = lang;
    await _storage.setLanguage(lang);
  }

  Future<void> toggleLanguage() async {
    final next = state == 'en' ? 'es' : 'en';
    await setLanguage(next);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref.watch(localStorageProvider));
});

// ─── Kit Size Provider ────────────────────────────────────────────────────────

class KitSizeNotifier extends StateNotifier<int> {
  final Q11LocalStorage _storage;
  KitSizeNotifier(this._storage) : super(_storage.getKitSize());

  Future<void> setKitSize(int size) async {
    state = size;
    await _storage.setKitSize(size);
  }
}

final kitSizeProvider = StateNotifierProvider<KitSizeNotifier, int>((ref) {
  return KitSizeNotifier(ref.watch(localStorageProvider));
});

// ─── Master Node Provider ─────────────────────────────────────────────────────

class MasterNodeNotifier extends StateNotifier<Q11Device> {
  final Q11LocalStorage _storage;
  MasterNodeNotifier(this._storage) : super(_storage.getMasterNode());

  Future<void> update(Q11Device updated) async {
    state = updated;
    await _storage.saveMasterNode(updated);
  }

  Future<void> saveMasterNode(Q11Device updated) async => update(updated);

  void refreshFromStorage() {
    state = _storage.getMasterNode();
  }
}

final masterNodeProvider = StateNotifierProvider<MasterNodeNotifier, Q11Device>((ref) {
  return MasterNodeNotifier(ref.watch(localStorageProvider));
});

// ─── Satellites Provider ──────────────────────────────────────────────────────

class SatellitesNotifier extends StateNotifier<List<Q11Device>> {
  final Q11LocalStorage _storage;
  SatellitesNotifier(this._storage) : super(_storage.getSatelliteNodes());

  Future<void> saveSatellite(Q11Device sat) async {
    await _storage.saveSatelliteNode(sat);
    state = _storage.getSatelliteNodes();
  }

  Future<void> addSatellite(Q11Device sat) async => saveSatellite(sat);

  Future<void> updateSatellite(int index, Q11Device sat) async {
    await _storage.saveSatelliteNode(sat);
    state = _storage.getSatelliteNodes();
  }

  Future<void> removeSatellite(String id) async {
    await _storage.removeSatelliteNode(id);
    state = _storage.getSatelliteNodes();
  }

  Future<void> ensureSatelliteSlots(int targetCount) async {
    final current = _storage.getSatelliteNodes().toList();
    if (current.length < targetCount) {
      for (int i = current.length; i < targetCount; i++) {
        final nodeNumber = i + 1;
        current.add(Q11Device(
          id: 'sat-0$nodeNumber',
          name: 'Satellite $nodeNumber',
          role: NodeRole.satellite,
          ssidDefault: 'q11-xxxx',
          wifiPassword: '',
          ipAddress: '192.168.1.${nodeNumber + 1}',
          patchStatus: PatchStatus.idle,
          isOnline: false,
        ));
      }
      for (final sat in current) {
        await _storage.saveSatelliteNode(sat);
      }
      state = _storage.getSatelliteNodes();
    }
  }

  void refreshFromStorage() {
    state = _storage.getSatelliteNodes();
  }
}

final satellitesProvider =
    StateNotifierProvider<SatellitesNotifier, List<Q11Device>>((ref) {
  return SatellitesNotifier(ref.watch(localStorageProvider));
});

// ─── WiFi Mesh Config Provider ────────────────────────────────────────────────

class WifiMeshConfigNotifier extends StateNotifier<WifiMeshConfig> {
  final Q11LocalStorage _storage;
  WifiMeshConfigNotifier(this._storage) : super(_storage.getWifiConfig());

  Future<void> saveConfig(WifiMeshConfig config) async {
    state = config;
    await _storage.saveWifiConfig(config);
  }

  Future<void> update(WifiMeshConfig config) => saveConfig(config);

  void refreshFromStorage() {
    state = _storage.getWifiConfig();
  }
}

final wifiMeshConfigProvider =
    StateNotifierProvider<WifiMeshConfigNotifier, WifiMeshConfig>((ref) {
  return WifiMeshConfigNotifier(ref.watch(localStorageProvider));
});

// ─── Custom Device Names / Alias Provider ─────────────────────────────────────

class CustomDeviceNamesNotifier extends StateNotifier<Map<String, String>> {
  final Q11LocalStorage _storage;
  CustomDeviceNamesNotifier(this._storage) : super(_storage.getCustomDeviceNames());

  Future<void> setDeviceName(String identifier, String name) async {
    await _storage.setDeviceName(identifier, name);
    state = _storage.getCustomDeviceNames();
  }

  void refreshFromStorage() {
    state = _storage.getCustomDeviceNames();
  }
}

final customDeviceNamesProvider =
    StateNotifierProvider<CustomDeviceNamesNotifier, Map<String, String>>((ref) {
  return CustomDeviceNamesNotifier(ref.watch(localStorageProvider));
});

