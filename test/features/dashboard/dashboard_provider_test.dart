import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/ble/ble_service.dart';
import 'package:sba_gas_scale/core/models/escalation_roster.dart';
import 'package:sba_gas_scale/features/dashboard/providers/dashboard_provider.dart';

class FakeBleService extends BleService {
  String? lastCommandSent;
  bool discoveryScanStarted = false;
  bool scanStopped = false;

  @override
  Future<void> sendCommand(String jsonCommand) async {
    lastCommandSent = jsonCommand;
  }

  @override
  Future<void> startDiscoveryScan({Duration timeout = const Duration(seconds: 15)}) async {
    discoveryScanStarted = true;
  }

  @override
  Future<void> stopScan() async {
    scanStopped = true;
  }
}

void main() {
  group('TelemetryNotifier', () {
    late FakeBleService fakeBle;
    late TelemetryNotifier notifier;

    setUp(() {
      fakeBle = FakeBleService();
      notifier = TelemetryNotifier(fakeBle);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initializes with default telemetry state', () {
      expect(notifier.state.gasPercentage, 14.5);
      expect(notifier.state.netWeight, 4.25);
      expect(notifier.state.selectedMaxKg, 6.0);
      expect(notifier.state.isConnected, isFalse);
    });

    test('startScan and stopScan interact with BLE engine', () async {
      await notifier.startScan();
      expect(fakeBle.discoveryScanStarted, isTrue);

      await notifier.stopScan();
      expect(fakeBle.scanStopped, isTrue);
    });

    test('connectDemo activates demo scale telemetry', () {
      notifier.connectDemo();
      expect(notifier.state.isConnected, isTrue);
      expect(notifier.state.gasPercentage, 14.8);
      expect(notifier.state.netWeight, 4.85);

      notifier.disconnect();
      expect(notifier.state.isConnected, isFalse);
    });

    test('toggleSiren updates state and dispatches JSON command', () {
      notifier.toggleSiren(true);
      expect(notifier.state.isSirenActive, isTrue);
      expect(fakeBle.lastCommandSent, '{"cmd":"SIREN","state":true}');

      notifier.toggleSiren(false);
      expect(notifier.state.isSirenActive, isFalse);
      expect(fakeBle.lastCommandSent, '{"cmd":"SIREN","state":false}');
    });

    test('setMaxKg updates state and dispatches SET_MAX command', () {
      notifier.setMaxKg(12.5);
      expect(notifier.state.selectedMaxKg, 12.5);
      expect(fakeBle.lastCommandSent, '{"cmd":"SET_MAX","max_kg":12.5}');
    });

    test('tare dispatches TARE command to BLE hardware', () {
      notifier.tare();
      expect(fakeBle.lastCommandSent, '{"cmd":"TARE"}');
    });

    test('syncRoster dispatches SYNC_ROSTER command with formatted recipients', () {
      const roster = EscalationRoster(
        smsRecipients: ['+2348011111111'],
        voiceRecipients: ['+2348022222222'],
      );
      notifier.syncRoster(roster);
      expect(
        fakeBle.lastCommandSent,
        '{"cmd":"SYNC_ROSTER","sms":["+2348011111111"],"voice":["+2348022222222"]}',
      );
    });
  });
}
