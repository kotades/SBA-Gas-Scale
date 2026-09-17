import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/telemetry_data.dart';
import '../../../core/models/escalation_roster.dart';
import '../../../core/ble/ble_service.dart';
import '../../../core/ble/ble_command_serializer.dart';

// ponytail: single BleService instance shared via provider, avoiding singleton pattern
final bleServiceProvider = Provider<BleService>((ref) {
  return BleService();
});

// ponytail: direct StateNotifier binding to BleService stream — no repository or interactor layers required
final telemetryProvider = StateNotifierProvider<TelemetryNotifier, TelemetryData>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return TelemetryNotifier(ble);
});

class TelemetryNotifier extends StateNotifier<TelemetryData> {
  final BleService _ble;
  StreamSubscription? _telemetrySub;

  TelemetryNotifier(this._ble)
      : super(const TelemetryData(
          gasPercentage: 14.5,
          netWeight: 4.25,
          selectedMaxKg: 6.0,
          alarmState: 0,
          isConnected: false,
        )) {
    // ponytail: stream telemetry directly from BLE service to state, no intermediate mapper
    _telemetrySub = _ble.telemetryStream.listen((data) {
      state = data;
    });
  }

  void scanAndConnect() {
    _ble.startScan(onDeviceFound: (device) => _ble.connect(device));
  }

  void disconnect() {
    _ble.disconnect();
  }

  void toggleSiren(bool active) {
    state = state.copyWith(isSirenActive: active);
    _ble.sendCommand(BleCommandSerializer.serializeSiren(active));
  }

  void setMaxKg(double maxKg) {
    state = state.copyWith(selectedMaxKg: maxKg);
    _ble.sendCommand(BleCommandSerializer.serializeSetMax(maxKg));
  }

  void tare() {
    _ble.sendCommand(BleCommandSerializer.serializeTare());
  }

  void syncRoster(EscalationRoster roster) {
    _ble.sendCommand(BleCommandSerializer.serializeSyncRoster(roster));
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }
}
