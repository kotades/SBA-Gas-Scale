import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/telemetry_data.dart';
import 'ble_constants.dart';

/// Background BLE engine managing GATT connection, MTU 512 negotiation,
/// JSON command writes, and real-time telemetry notifications.
class BleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;

  final _telemetryController = StreamController<TelemetryData>.broadcast();
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  TelemetryData _currentTelemetry = const TelemetryData();
  TelemetryData get currentTelemetry => _currentTelemetry;

  /// Start scanning for the SBA Gas Detector appliance.
  Future<void> startScan({required Function(BluetoothDevice) onDeviceFound}) async {
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == BleConstants.deviceName ||
            r.advertisementData.serviceUuids.contains(Guid(BleConstants.serviceUuid))) {
          FlutterBluePlus.stopScan();
          onDeviceFound(r.device);
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(
      withServices: [Guid(BleConstants.serviceUuid)],
      timeout: const Duration(seconds: 15),
    );
  }

  /// Connect to the detected hardware, negotiate MTU size, and discover telemetry characteristics.
  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    await device.connect(autoConnect: false);
    _connectionStateController.add(true);
    _currentTelemetry = _currentTelemetry.copyWith(isConnected: true);
    _telemetryController.add(_currentTelemetry);

    // MTU Size Negotiator Protocol: Request 512 bytes to prevent phone roster truncation
    try {
      await device.requestMtu(BleConstants.targetMtu);
    } catch (_) {
      // Platform-specific fallback if device already locked MTU
    }

    // Discover GATT Services & Characteristics
    final services = await device.discoverServices();
    for (var s in services) {
      if (s.uuid == Guid(BleConstants.serviceUuid)) {
        for (var c in s.characteristics) {
          if (c.uuid == Guid(BleConstants.characteristicUuid)) {
            _targetCharacteristic = c;
            await c.setNotifyValue(true);
            c.onValueReceived.listen(_handleIncomingData);
            break;
          }
        }
      }
    }
  }

  /// Parses incoming notification streams (supporting both comma-delimited strings and JSON packets).
  void _handleIncomingData(List<int> bytes) {
    if (bytes.isEmpty) return;
    final payload = utf8.decode(bytes).trim();

    // Check for JSON payload: {"gas": 14.5, "weight": 4.25, "alarm": 0}
    if (payload.startsWith("{") && payload.endsWith("}")) {
      try {
        final map = jsonDecode(payload) as Map<String, dynamic>;
        _currentTelemetry = _currentTelemetry.copyWith(
          gasPercentage: (map['gas'] as num?)?.toDouble() ?? _currentTelemetry.gasPercentage,
          netWeight: (map['weight'] as num?)?.toDouble() ?? _currentTelemetry.netWeight,
          alarmState: (map['alarm'] as num?)?.toInt() ?? _currentTelemetry.alarmState,
        );
        _telemetryController.add(_currentTelemetry);
        return;
      } catch (_) {}
    }

    // Parse legacy DATA:<gas>,<weight>,<alarm>
    if (payload.startsWith("DATA:")) {
      final parts = payload.substring(5).split(",");
      if (parts.length >= 3) {
        final gas = double.tryParse(parts[0]) ?? _currentTelemetry.gasPercentage;
        final weight = double.tryParse(parts[1]) ?? _currentTelemetry.netWeight;
        final alarm = int.tryParse(parts[2]) ?? _currentTelemetry.alarmState;

        _currentTelemetry = _currentTelemetry.copyWith(
          gasPercentage: gas,
          netWeight: weight,
          alarmState: alarm,
        );
        _telemetryController.add(_currentTelemetry);
      }
    }
  }

  /// Dispatch a serialized JSON command string over BLE.
  Future<void> sendCommand(String jsonCommand) async {
    if (_targetCharacteristic == null) return;
    final bytes = utf8.encode(jsonCommand);
    await _targetCharacteristic!.write(bytes, withoutResponse: false);
  }

  /// Disconnect and cleanup GATT connections.
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _targetCharacteristic = null;
    _currentTelemetry = _currentTelemetry.copyWith(isConnected: false);
    _connectionStateController.add(false);
    _telemetryController.add(_currentTelemetry);
  }
}
