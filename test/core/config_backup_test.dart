import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motoq11_saver/core/storage/q11_local_storage.dart';
import 'package:motoq11_saver/features/models/models.dart';

void main() {
  group('Q11LocalStorage & Config Backup', () {
    late Q11LocalStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = Q11LocalStorage(prefs);
    });

    test('returns default master node if none saved', () {
      final master = storage.getMasterNode();
      expect(master.id, equals('master-01'));
      expect(master.ipAddress, equals('192.168.1.1'));
      expect(master.role, equals(NodeRole.master));
    });

    test('saves and updates master node', () async {
      const updated = Q11Device(
        id: 'master-01',
        name: 'Main Living Room',
        ssidDefault: 'q11-master-test',
        wifiPassword: 'Password123!',
        ipAddress: '192.168.1.1',
        patchStatus: PatchStatus.completed,
        isOnline: true,
      );
      await storage.saveMasterNode(updated);
      final retrieved = storage.getMasterNode();
      expect(retrieved.name, equals('Main Living Room'));
      expect(retrieved.ssidDefault, equals('q11-master-test'));
      expect(retrieved.patchStatus, equals(PatchStatus.completed));
      expect(retrieved.isOnline, isTrue);
    });

    test('saves, updates, and removes satellite nodes', () async {
      const sat1 = Q11Device(
        id: 'sat-1',
        name: 'Satellite 1',
        role: NodeRole.satellite,
        ipAddress: '192.168.1.20',
      );
      const sat2 = Q11Device(
        id: 'sat-2',
        name: 'Satellite 2',
        role: NodeRole.satellite,
        ipAddress: '192.168.1.21',
      );

      await storage.saveSatelliteNode(sat1);
      await storage.saveSatelliteNode(sat2);
      expect(storage.getSatelliteNodes().length, equals(2));

      await storage.removeSatelliteNode('sat-1');
      final remaining = storage.getSatelliteNodes();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('sat-2'));
    });

    test('exports and imports full configuration JSON', () async {
      await storage.setKitSize(2);
      await storage.setLanguage('es');
      await storage.saveMasterNode(const Q11Device(
        id: 'master-01',
        name: 'Gateway Root',
        ssidDefault: 'q11-orig',
      ));
      await storage.saveSatelliteNode(const Q11Device(
        id: 'sat-1',
        name: 'Kitchen Node',
      ));
      await storage.saveWifiConfig(const WifiMeshConfig(
        home24Ssid: 'MeshHome24',
        home5Ssid: 'MeshHome5',
      ));

      final exportedJson = storage.exportFullConfigJson();
      expect(exportedJson, contains('Gateway Root'));
      expect(exportedJson, contains('Kitchen Node'));
      expect(exportedJson, contains('MeshHome24'));

      // Clean storage and re-import
      SharedPreferences.setMockInitialValues({});
      final newPrefs = await SharedPreferences.getInstance();
      final freshStorage = Q11LocalStorage(newPrefs);

      final success = await freshStorage.importFullConfigJson(exportedJson);
      expect(success, isTrue);
      expect(freshStorage.getKitSize(), equals(2));
      expect(freshStorage.getLanguage(), equals('es'));
      expect(freshStorage.getMasterNode().name, equals('Gateway Root'));
      expect(freshStorage.getSatelliteNodes().length, equals(1));
      expect(freshStorage.getWifiConfig().home24Ssid, equals('MeshHome24'));
    });

    test('saves and remembers custom device names by IP and MAC', () async {
      await storage.setDeviceName('10.10.11.1', 'Living Room Gateway');
      await storage.setDeviceName('c8:c7:50:dd:b5:18', 'Upstairs Bedroom Satellite');

      expect(storage.getDeviceName('10.10.11.1'), equals('Living Room Gateway'));
      expect(storage.getDeviceName('c8:c7:50:dd:b5:18'), equals('Upstairs Bedroom Satellite'));

      // Case insensitive retrieval
      expect(storage.getDeviceName('C8:C7:50:DD:B5:18'), equals('Upstairs Bedroom Satellite'));

      final all = storage.getCustomDeviceNames();
      expect(all.length, equals(2));

      // Clear name
      await storage.setDeviceName('10.10.11.1', '');
      expect(storage.getDeviceName('10.10.11.1'), isNull);
    });
  });
}
