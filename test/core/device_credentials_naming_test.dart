import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motoq11_saver/core/storage/q11_local_storage.dart';
import 'package:motoq11_saver/features/models/models.dart';

void main() {
  group('Q11LocalStorage Credentials & Friendly Naming', () {
    late Q11LocalStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = Q11LocalStorage(prefs);
    });

    test('stores and retrieves master credentials manually', () async {
      const manualMaster = Q11Device(
        id: 'master-01',
        name: 'Living Room Router',
        role: NodeRole.master,
        ssidDefault: 'q11-manual',
        wifiPassword: 'mySecretMasterPass123',
        ipAddress: '10.10.11.1',
        mac: 'c8:c7:50:aa:bb:cc',
        serialNumber: '2081AA999999',
      );

      await storage.saveMasterNode(manualMaster);
      final retrieved = storage.getMasterNode();

      expect(retrieved.name, equals('Living Room Router'));
      expect(retrieved.ssidDefault, equals('q11-manual'));
      expect(retrieved.wifiPassword, equals('mySecretMasterPass123'));
      expect(retrieved.ipAddress, equals('10.10.11.1'));
      expect(retrieved.mac, equals('c8:c7:50:aa:bb:cc'));
      expect(retrieved.serialNumber, equals('2081AA999999'));
    });

    test('stores and retrieves satellite credentials manually', () async {
      const manualSat = Q11Device(
        id: 'sat-01',
        name: 'Basement Extender',
        role: NodeRole.satellite,
        ssidDefault: 'q11-sat1',
        wifiPassword: 'satPassword456',
        ipAddress: '10.10.11.130',
        mac: 'c8:c7:50:11:22:33',
        serialNumber: '2081AA888888',
      );

      await storage.saveSatelliteNode(manualSat);
      final list = storage.getSatelliteNodes();

      expect(list.length, equals(1));
      expect(list.first.name, equals('Basement Extender'));
      expect(list.first.ssidDefault, equals('q11-sat1'));
      expect(list.first.wifiPassword, equals('satPassword456'));
      expect(list.first.ipAddress, equals('10.10.11.130'));
      expect(list.first.mac, equals('c8:c7:50:11:22:33'));
      expect(list.first.serialNumber, equals('2081AA888888'));
    });

    test('sets, gets and clears custom friendly device name by IP and MAC', () async {
      await storage.setDeviceName('10.10.11.1', 'Main Gateway Router');
      await storage.setDeviceName('C8:C7:50:DD:B6:20', 'Main Gateway MAC Alias');

      expect(storage.getDeviceName('10.10.11.1'), equals('Main Gateway Router'));
      // Case-insensitive lookup check
      expect(storage.getDeviceName('c8:c7:50:dd:b6:20'), equals('Main Gateway MAC Alias'));

      // Clear name
      await storage.setDeviceName('10.10.11.1', '');
      expect(storage.getDeviceName('10.10.11.1'), isNull);
    });
  });
}
