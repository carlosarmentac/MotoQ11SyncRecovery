import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/models/models.dart';

class Q11LocalStorage {
  static const String keyMasterNode = 'master_node';
  static const String keySatellites = 'satellite_nodes';
  static const String keyWifiConfig = 'wifi_mesh_config';
  static const String keyAppLanguage = 'app_language';
  static const String keyKitSize = 'kit_size';

  final SharedPreferences _prefs;

  Q11LocalStorage(this._prefs);

  static Future<Q11LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return Q11LocalStorage(prefs);
  }

  // ─── Master Node Storage ──────────────────────────────────────────────────

  Future<void> saveMasterNode(Q11Device device) async {
    await _prefs.setString(keyMasterNode, jsonEncode(device.toJson()));
  }

  Q11Device getMasterNode() {
    final jsonStr = _prefs.getString(keyMasterNode);
    if (jsonStr == null || jsonStr.isEmpty) {
      return defaultMaster();
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Q11Device.fromJson(map);
    } catch (_) {
      return defaultMaster();
    }
  }

  Q11Device defaultMaster() {
    return const Q11Device(
      id: 'master-01',
      name: 'Master Gateway',
      role: NodeRole.master,
      ssidDefault: 'q11-xxxx',
      wifiPassword: '',
      ipAddress: '192.168.1.1',
      patchStatus: PatchStatus.idle,
      isOnline: false,
    );
  }

  // ─── Satellite Nodes Storage ──────────────────────────────────────────────

  List<Q11Device> getSatelliteNodes() {
    final jsonStr = _prefs.getString(keySatellites);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => Q11Device.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSatelliteNode(Q11Device node) async {
    final current = getSatelliteNodes().toList();
    final index = current.indexWhere((it) => it.id == node.id);
    if (index != -1) {
      current[index] = node;
    } else {
      current.add(node);
    }
    await _saveSatelliteList(current);
  }

  Future<void> removeSatelliteNode(String nodeId) async {
    final current = getSatelliteNodes().where((it) => it.id != nodeId).toList();
    await _saveSatelliteList(current);
  }

  Future<void> _saveSatelliteList(List<Q11Device> list) async {
    final encoded = jsonEncode(list.map((it) => it.toJson()).toList());
    await _prefs.setString(keySatellites, encoded);
  }

  // ─── WiFi Mesh Config Storage ─────────────────────────────────────────────

  Future<void> saveWifiConfig(WifiMeshConfig config) async {
    await _prefs.setString(keyWifiConfig, jsonEncode(config.toJson()));
  }

  WifiMeshConfig getWifiConfig() {
    final jsonStr = _prefs.getString(keyWifiConfig);
    if (jsonStr == null || jsonStr.isEmpty) {
      return const WifiMeshConfig();
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WifiMeshConfig.fromJson(map);
    } catch (_) {
      return const WifiMeshConfig();
    }
  }

  // ─── Language & Preferences ───────────────────────────────────────────────

  String getLanguage() {
    return _prefs.getString(keyAppLanguage) ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(keyAppLanguage, lang);
  }

  int getKitSize() {
    return _prefs.getInt(keyKitSize) ?? 3;
  }

  Future<void> setKitSize(int size) async {
    await _prefs.setInt(keyKitSize, size);
  }

  // ─── Export & Import Full Network Configuration ────────────────────────────

  String exportFullConfigJson() {
    final root = {
      'version': 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'kitSize': getKitSize(),
      'language': getLanguage(),
      'masterNode': getMasterNode().toJson(),
      'satelliteNodes': getSatelliteNodes().map((it) => it.toJson()).toList(),
      'wifiConfig': getWifiConfig().toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(root);
  }

  Future<bool> importFullConfigJson(String jsonStr) async {
    try {
      final root = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (root.containsKey('kitSize')) {
        await setKitSize((root['kitSize'] as num).toInt());
      }
      if (root.containsKey('language')) {
        await setLanguage(root['language'] as String);
      }
      if (root.containsKey('masterNode')) {
        await saveMasterNode(
            Q11Device.fromJson(root['masterNode'] as Map<String, dynamic>));
      }
      if (root.containsKey('satelliteNodes')) {
        final list = root['satelliteNodes'] as List<dynamic>;
        final satellites = list
            .map((item) => Q11Device.fromJson(item as Map<String, dynamic>))
            .toList();
        await _saveSatelliteList(satellites);
      }
      if (root.containsKey('wifiConfig')) {
        await saveWifiConfig(
            WifiMeshConfig.fromJson(root['wifiConfig'] as Map<String, dynamic>));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
