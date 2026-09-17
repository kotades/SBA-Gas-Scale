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
  Timer? _demoTimer;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null || _demoTimer != null;

  final _telemetryController = StreamController<TelemetryData>.broadcast();
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  Stream<List<ScanResult>> get scanResultsStream => FlutterBluePlus.scanResults;
  Stream<bool> get isScanningStream => FlutterBluePlus.isScanning;

  TelemetryData _currentTelemetry = const TelemetryData();
  TelemetryData get currentTelemetry => _currentTelemetry;

  /// Start scanning for all nearby BLE peripherals to populate discovered devices list.
  Future<void> startDiscoveryScan({Duration timeout = const Duration(seconds: 15)}) async {
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (_) {
      // Handle platforms or web where startScan may require permission
    }
  }

  /// Stop active BLE scanning.
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  /// Start scanning for the SBA Gas Detector appliance specifically (legacy quick connect).
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

  /// Connect to a simulated scale for Chrome Web or offline testing.
  void connectDemoDevice() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _connectedDevice = null;
    _targetCharacteristic = null;

    _currentTelemetry = _currentTelemetry.copyWith(
      isConnected: true,
      gasPercentage: 14.8,
      netWeight: 4.85,
      alarmState: 0,
    );
    _connectionStateController.add(true);
    _telemetryController.add(_currentTelemetry);

    _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_currentTelemetry.isConnected) {
        timer.cancel();
        return;
      }
      final delta = ((timer.tick % 5) - 2) * 0.05;
      _currentTelemetry = _currentTelemetry.copyWith(
        gasPercentage: double.parse((14.8 + delta).toStringAsFixed(1)),
        netWeight: double.parse((4.85 + delta * 0.1).toStringAsFixed(2)),
      );
      _telemetryController.add(_currentTelemetry);
    });
  }

  /// Disconnect and cleanup GATT connections.
  Future<void> disconnect() async {
    _demoTimer?.cancel();
    _demoTimer = null;
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _targetCharacteristic = null;
    _currentTelemetry = _currentTelemetry.copyWith(isConnected: false);
    _connectionStateController.add(false);
    _telemetryController.add(_currentTelemetry);
  }
}
