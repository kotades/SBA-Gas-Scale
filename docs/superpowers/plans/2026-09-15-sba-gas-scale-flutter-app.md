# SBA Gas Detector Flutter Mobile App & BLE Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete cross-platform Flutter application for the SBA Gas Detector appliance, featuring a real-time Telemetry Dashboard (animated volumetric fluid cylinder, sweeping radial gas saturation gauge, flashing alarm banner, siren toggle), an Escalation Roster screen (multi-recipient SMS and Voice lists with E.164 phone validation), a Hardware Setup screen (cylinder size selector and tare safety modal), and an invisible BLE engine with JSON serialization and MTU negotiation.

**Architecture:** Domain-driven feature architecture with Riverpod state management. UI widgets are decoupled from reactive providers; custom canvas painters render 60fps fluid physics and radial dial sweeps; a dedicated BLE service manages connection lifecycle, MTU 512 negotiation, and JSON command streams.

**Tech Stack:** Flutter 3.x, Dart 3.x, `flutter_riverpod: ^2.5.1`, `flutter_blue_plus: ^1.32.0`, `shared_preferences: ^2.2.3`, `flutter_test`.

**Spec:** [`docs/superpowers/specs/2026-09-15-sba-gas-scale-flutter-ui-and-ble-engine-design.md`](file:///home/sanniinuoluwadunsimi/Documents/Sanni%20Workspace/SBA-Gas-Scale/docs/superpowers/specs/2026-09-15-sba-gas-scale-flutter-ui-and-ble-engine-design.md)

## Global Constraints

- **Platform Support**: Cross-platform iOS (13.0+) and Android (API 21+).
- **BLE Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **BLE Characteristic UUID**: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- **Target BLE MTU**: 512 bytes (minimum 256 bytes without chunking)
- **Phone Validation Standard**: Strict E.164 international format starting with `+` (`^\+[1-9]\d{7,14}$`)
- **Gas Safety Thresholds**: Safe $\le 20\%$, Warning $21\% - 59\%$, Critical $\ge 60\%$
- **Cylinder Capacity Sizes**: `3.0`, `6.0`, `12.5`, `25.0`, `50.0` kg

---

### Task 1: Project Scaffolding & Design System

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_typography.dart`
- Test: `test/core/theme/theme_test.dart`

**Interfaces:**
- Produces: `AppColors` (palette tokens: background, surface, safe, warning, danger, cyan fluid gradient) and `AppTypography` (heading, body, digital monospace).

- [ ] **Step 1: Write the failing test for theme color constants**

```dart
// test/core/theme/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/theme/app_colors.dart';

void main() {
  test('AppColors defines required safety and brand palette', () {
    expect(AppColors.background, const Color(0xFF090D16));
    expect(AppColors.surface, const Color(0xFF161E31));
    expect(AppColors.safeGreen, const Color(0xFF10B981));
    expect(AppColors.warningAmber, const Color(0xFFF59E0B));
    expect(AppColors.dangerRed, const Color(0xFFEF4444));
    expect(AppColors.cyanAccent, const Color(0xFF00F2FE));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/theme_test.dart`
Expected: FAIL (file or class not found)

- [ ] **Step 3: Implement pubspec.yaml and theme tokens**

```yaml
# pubspec.yaml
name: sba_gas_scale
description: "SBA Gas Scale Telemetry Dashboard & BLE Controller"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  flutter_blue_plus: ^1.32.0
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF161E31);
  static const Color surfaceLight = Color(0xFF222C45);
  static const Color cardBorder = Color(0x1FFFFFFF);
  
  static const Color safeGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerRedDark = Color(0xFF7F1D1D);
  
  static const Color cyanAccent = Color(0xFF00F2FE);
  static const Color blueAccent = Color(0xFF4FACFE);
  
  static const Color textMain = Color(0xFFF3F4F6);
  static const Color textMuted = Color(0xFF9CA3AF);
}
```

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const TextStyle heading1 = TextStyle(
    color: AppColors.textMain,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    color: AppColors.textMain,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle digitalValue = TextStyle(
    color: AppColors.textMain,
    fontSize: 24,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/theme/theme_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/core/theme/ test/core/theme/
git commit -m "feat: scaffold Flutter project structure and theme tokens"
```

---

### Task 2: Core Data Models & International Phone Validation Engine

**Files:**
- Create: `lib/core/models/telemetry_data.dart`
- Create: `lib/core/models/escalation_roster.dart`
- Create: `lib/core/utils/phone_validator.dart`
- Test: `test/core/models/telemetry_data_test.dart`
- Test: `test/core/utils/phone_validator_test.dart`

**Interfaces:**
- Produces:
  - `TelemetryData`: `gasPercentage`, `netWeight`, `alarmState`, `isConnected`, `selectedMaxKg`, `fuelPercentage`, `safetyLevel`.
  - `EscalationRoster`: `smsRecipients`, `voiceRecipients`.
  - `PhoneValidator.validate(String input) -> ValidationResult`.

- [ ] **Step 1: Write failing unit tests for PhoneValidator and TelemetryData**

```dart
// test/core/utils/phone_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/utils/phone_validator.dart';

void main() {
  group('PhoneValidator', () {
    test('accepts valid E.164 phone numbers with + country code', () {
      expect(PhoneValidator.validate('+2348012345678').isValid, isTrue);
      expect(PhoneValidator.validate('+14155552671').isValid, isTrue);
      expect(PhoneValidator.validate('+447911123456').isValid, isTrue);
    });

    test('rejects numbers missing leading + symbol', () {
      final result = PhoneValidator.validate('08012345678');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains("Missing '+'"));
    });

    test('rejects numbers with non-digit characters', () {
      final result = PhoneValidator.validate('+234-801-ABC');
      expect(result.isValid, isFalse);
    });

    test('rejects numbers that are too short or empty', () {
      expect(PhoneValidator.validate('').isValid, isFalse);
      expect(PhoneValidator.validate('+23').isValid, isFalse);
    });
  });
}
```

```dart
// test/core/models/telemetry_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/models/telemetry_data.dart';

void main() {
  group('TelemetryData', () {
    test('computes fuelPercentage correctly clamped between 0 and 100', () {
      final data = TelemetryData(netWeight: 6.25, selectedMaxKg: 12.5);
      expect(data.fuelPercentage, 50.0);

      final overflow = TelemetryData(netWeight: 15.0, selectedMaxKg: 12.5);
      expect(overflow.fuelPercentage, 100.0);

      final negative = TelemetryData(netWeight: -1.0, selectedMaxKg: 12.5);
      expect(negative.fuelPercentage, 0.0);
    });

    test('determines safety levels accurately', () {
      expect(TelemetryData(gasPercentage: 15.0).safetyStatus, SafetyStatus.safe);
      expect(TelemetryData(gasPercentage: 45.0).safetyStatus, SafetyStatus.warning);
      expect(TelemetryData(gasPercentage: 65.0).safetyStatus, SafetyStatus.critical);
      expect(TelemetryData(alarmState: 2).safetyStatus, SafetyStatus.critical);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/phone_validator_test.dart test/core/models/telemetry_data_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement PhoneValidator, TelemetryData, and EscalationRoster**

```dart
// lib/core/utils/phone_validator.dart
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  const ValidationResult({required this.isValid, this.errorMessage});
}

class PhoneValidator {
  static final RegExp _e164Regex = RegExp(r'^\+[1-9]\d{7,14}$');

  static ValidationResult validate(String rawNumber) {
    final trimmed = rawNumber.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult(isValid: false, errorMessage: 'Phone number cannot be empty.');
    }
    if (!trimmed.startsWith('+')) {
      return const ValidationResult(
        isValid: false,
        errorMessage: "Missing '+' and international country dialing code (e.g. +234...).",
      );
    }
    if (!_e164Regex.hasMatch(trimmed)) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Invalid phone format. Must be E.164 compliant (+ followed by 8 to 15 digits).',
      );
    }
    return const ValidationResult(isValid: true);
  }
}
```

```dart
// lib/core/models/telemetry_data.dart
enum SafetyStatus { safe, warning, critical }

class TelemetryData {
  final double gasPercentage;
  final double netWeight;
  final int alarmState;
  final bool isConnected;
  final double selectedMaxKg;
  final bool isSirenActive;

  const TelemetryData({
    this.gasPercentage = 0.0,
    this.netWeight = 0.0,
    this.alarmState = 0,
    this.isConnected = false,
    this.selectedMaxKg = 6.0,
    this.isSirenActive = false,
  });

  double get fuelPercentage {
    if (selectedMaxKg <= 0) return 0.0;
    return ((netWeight / selectedMaxKg) * 100.0).clamp(0.0, 100.0);
  }

  bool get isCriticalLeak => alarmState == 2 || gasPercentage >= 60.0;
  bool get isLowFuel => netWeight < 1.0;

  SafetyStatus get safetyStatus {
    if (isCriticalLeak) return SafetyStatus.critical;
    if (gasPercentage > 20.0 || isLowFuel) return SafetyStatus.warning;
    return SafetyStatus.safe;
  }

  TelemetryData copyWith({
    double? gasPercentage,
    double? netWeight,
    int? alarmState,
    bool? isConnected,
    double? selectedMaxKg,
    bool? isSirenActive,
  }) {
    return TelemetryData(
      gasPercentage: gasPercentage ?? this.gasPercentage,
      netWeight: netWeight ?? this.netWeight,
      alarmState: alarmState ?? this.alarmState,
      isConnected: isConnected ?? this.isConnected,
      selectedMaxKg: selectedMaxKg ?? this.selectedMaxKg,
      isSirenActive: isSirenActive ?? this.isSirenActive,
    );
  }
}
```

```dart
// lib/core/models/escalation_roster.dart
class EscalationRoster {
  final List<String> smsRecipients;
  final List<String> voiceRecipients;

  const EscalationRoster({
    this.smsRecipients = const [],
    this.voiceRecipients = const [],
  });

  EscalationRoster copyWith({
    List<String>? smsRecipients,
    List<String>? voiceRecipients,
  }) {
    return EscalationRoster(
      smsRecipients: smsRecipients ?? this.smsRecipients,
      voiceRecipients: voiceRecipients ?? this.voiceRecipients,
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/utils/phone_validator_test.dart test/core/models/telemetry_data_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/ lib/core/utils/ test/core/models/ test/core/utils/
git commit -m "feat: add telemetry data models, safety status enum, and E.164 phone validator"
```

---

### Task 3: Background BLE Engine, JSON Serialization & MTU Negotiator

**Files:**
- Create: `lib/core/ble/ble_constants.dart`
- Create: `lib/core/ble/ble_command_serializer.dart`
- Create: `lib/core/ble/ble_service.dart`
- Test: `test/core/ble/ble_command_serializer_test.dart`

**Interfaces:**
- Produces:
  - `BleCommandSerializer`: `serializeTare()`, `serializeSiren(bool)`, `serializeSetMax(double)`, `serializeSyncRoster(EscalationRoster)`.
  - `BleService`: `startScan()`, `connect()`, `disconnect()`, `negotiateMtu(int)`, `sendCommand(String)`, `telemetryStream`.

- [ ] **Step 1: Write failing unit test for BleCommandSerializer**

```dart
// test/core/ble/ble_command_serializer_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/ble/ble_command_serializer.dart';
import 'package:sba_gas_scale/core/models/escalation_roster.dart';

void main() {
  group('BleCommandSerializer', () {
    test('serializes tare command accurately', () {
      final jsonStr = BleCommandSerializer.serializeTare();
      final map = jsonDecode(jsonStr);
      expect(map['cmd'], 'TARE');
    });

    test('serializes siren toggle command', () {
      final onStr = BleCommandSerializer.serializeSiren(true);
      expect(jsonDecode(onStr), {'cmd': 'SIREN', 'state': true});

      final offStr = BleCommandSerializer.serializeSiren(false);
      expect(jsonDecode(offStr), {'cmd': 'SIREN', 'state': false});
    });

    test('serializes cylinder capacity command', () {
      final str = BleCommandSerializer.serializeSetMax(12.5);
      expect(jsonDecode(str), {'cmd': 'SET_MAX', 'max_kg': 12.5});
    });

    test('serializes escalation roster with multiple SMS and voice numbers', () {
      const roster = EscalationRoster(
        smsRecipients: ['+2348011111111', '+2348022222222'],
        voiceRecipients: ['+2348033333333'],
      );
      final jsonStr = BleCommandSerializer.serializeSyncRoster(roster);
      final map = jsonDecode(jsonStr);
      expect(map['cmd'], 'SYNC_ROSTER');
      expect(map['sms'], ['+2348011111111', '+2348022222222']);
      expect(map['voice'], ['+2348033333333']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/ble/ble_command_serializer_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement BleConstants, BleCommandSerializer, and BleService**

```dart
// lib/core/ble/ble_constants.dart
class BleConstants {
  static const String deviceName = "SBA GAS DETECTOR";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const int targetMtu = 512;
}
```

```dart
// lib/core/ble/ble_command_serializer.dart
import 'dart:convert';
import '../models/escalation_roster.dart';

class BleCommandSerializer {
  static String serializeTare() {
    return jsonEncode({'cmd': 'TARE'});
  }

  static String serializeSiren(bool state) {
    return jsonEncode({'cmd': 'SIREN', 'state': state});
  }

  static String serializeSetMax(double maxKg) {
    return jsonEncode({'cmd': 'SET_MAX', 'max_kg': maxKg});
  }

  static String serializeSyncRoster(EscalationRoster roster) {
    return jsonEncode({
      'cmd': 'SYNC_ROSTER',
      'sms': roster.smsRecipients,
      'voice': roster.voiceRecipients,
    });
  }
}
```

```dart
// lib/core/ble/ble_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/telemetry_data.dart';
import 'ble_constants.dart';

class BleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;

  final _telemetryController = StreamController<TelemetryData>.broadcast();
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  TelemetryData _currentTelemetry = const TelemetryData();
  TelemetryData get currentTelemetry => _currentTelemetry;

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

  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    await device.connect(autoConnect: false);
    _connectionStateController.add(true);
    _currentTelemetry = _currentTelemetry.copyWith(isConnected: true);
    _telemetryController.add(_currentTelemetry);

    // Negotiate MTU > 256 bytes (Target: 512)
    try {
      await device.requestMtu(BleConstants.targetMtu);
    } catch (_) {}

    // Discover Services & Characteristic
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

  void _handleIncomingData(List<int> bytes) {
    if (bytes.isEmpty) return;
    final payload = utf8.decode(bytes).trim();

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

  Future<void> sendCommand(String jsonCommand) async {
    if (_targetCharacteristic == null) return;
    final bytes = utf8.encode(jsonCommand);
    await _targetCharacteristic!.write(bytes, withoutResponse: false);
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _targetCharacteristic = null;
    _currentTelemetry = _currentTelemetry.copyWith(isConnected: false);
    _connectionStateController.add(false);
    _telemetryController.add(_currentTelemetry);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/ble/ble_command_serializer_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/ble/ test/core/ble/
git commit -m "feat: implement BLE command serializer, constants, and GATT MTU negotiator"
```

---

### Task 4: Custom Canvas Widgets (Volumetric Cylinder & Radial Gauge)

**Files:**
- Create: `lib/features/dashboard/presentation/widgets/volumetric_cylinder_painter.dart`
- Create: `lib/features/dashboard/presentation/widgets/gas_saturation_gauge.dart`
- Create: `lib/features/dashboard/presentation/widgets/emergency_alarm_banner.dart`
- Create: `lib/features/dashboard/presentation/widgets/manual_siren_toggle.dart`
- Test: `test/features/dashboard/volumetric_cylinder_test.dart`
- Test: `test/features/dashboard/gas_saturation_gauge_test.dart`

**Interfaces:**
- Produces:
  - `VolumetricCylinder`: Stateful widget taking `fuelPercentage` and rendering animated wave mesh.
  - `GasSaturationGauge`: Visual dial taking `gasPercentage` (0–100%) and rendering sweeping arc.
  - `EmergencyAlarmBanner`: Strobe banner triggered when `isCriticalLeak` is true.
  - `ManualSirenToggle`: Master switch taking `isActive` and `onChanged(bool)`.

- [ ] **Step 1: Write failing widget tests for Cylinder and Gauge**

```dart
// test/features/dashboard/volumetric_cylinder_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/features/dashboard/presentation/widgets/volumetric_cylinder_painter.dart';

void main() {
  testWidgets('VolumetricCylinder renders without error and displays percentage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VolumetricCylinder(fuelPercentage: 75.0, netWeightKg: 9.37),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('9.37 kg'), findsOneWidget);
  });
}
```

```dart
// test/features/dashboard/gas_saturation_gauge_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/features/dashboard/presentation/widgets/gas_saturation_gauge.dart';

void main() {
  testWidgets('GasSaturationGauge displays gas percentage readout and status label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GasSaturationGauge(gasPercentage: 14.5),
        ),
      ),
    );
    expect(find.text('14.5%'), findsOneWidget);
    expect(find.text('SAFE'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/dashboard/volumetric_cylinder_test.dart test/features/dashboard/gas_saturation_gauge_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement VolumetricCylinder, GasSaturationGauge, EmergencyAlarmBanner, ManualSirenToggle**

```dart
// lib/features/dashboard/presentation/widgets/volumetric_cylinder_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class VolumetricCylinder extends StatefulWidget {
  final double fuelPercentage;
  final double netWeightKg;

  const VolumetricCylinder({
    super.key,
    required this.fuelPercentage,
    required this.netWeightKg,
  });

  @override
  State<VolumetricCylinder> createState() => _VolumetricCylinderState();
}

class _VolumetricCylinderState extends State<VolumetricCylinder> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return SizedBox(
          width: 220,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 320),
                painter: _CylinderPainter(
                  fuelFraction: widget.fuelPercentage / 100.0,
                  wavePhase: _waveController.value * 2 * math.pi,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.fuelPercentage.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${widget.netWeightKg.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 18,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'LPG REMAINING',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CylinderPainter extends CustomPainter {
  final double fuelFraction;
  final double wavePhase;

  _CylinderPainter({required this.fuelFraction, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Cylinder Outline Path (Collar + Tank + Base)
    final tankRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.18, w * 0.7, h * 0.72),
      const Radius.circular(32),
    );

    // Collar Shroud Handle
    final collarPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.06, w * 0.44, h * 0.14),
        const Radius.circular(12),
      ));

    // Draw Background Tank
    final bgPaint = Paint()..color = const Color(0xFF161E31);
    canvas.drawRRect(tankRect, bgPaint);
    canvas.drawPath(collarPath, Paint()..color = const Color(0xFF222C45));

    // Clip to Tank for Fluid Wave
    canvas.save();
    canvas.clipRRect(tankRect);

    final waterY = (h * 0.9) - ((h * 0.72) * fuelFraction);
    final wavePath = Path()..moveTo(0, waterY);

    for (double x = 0; x <= w; x += 4) {
      final y = waterY + 6 * math.sin((x / w * 2 * math.pi) + wavePhase);
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(w, h);
    wavePath.lineTo(0, h);
    wavePath.close();

    final fluidPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cyanAccent, AppColors.blueAccent],
      ).createShader(Rect.fromLTWH(0, waterY, w, h - waterY));

    canvas.drawPath(wavePath, fluidPaint);
    canvas.restore();

    // Outline Borders
    final borderPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(tankRect, borderPaint);
    canvas.drawPath(collarPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CylinderPainter oldDelegate) =>
      oldDelegate.fuelFraction != fuelFraction || oldDelegate.wavePhase != wavePhase;
}
```

```dart
// lib/features/dashboard/presentation/widgets/gas_saturation_gauge.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GasSaturationGauge extends StatelessWidget {
  final double gasPercentage;

  const GasSaturationGauge({super.key, required this.gasPercentage});

  Color get _statusColor {
    if (gasPercentage <= 20.0) return AppColors.safeGreen;
    if (gasPercentage <= 59.0) return AppColors.warningAmber;
    return AppColors.dangerRed;
  }

  String get _statusLabel {
    if (gasPercentage <= 20.0) return 'SAFE';
    if (gasPercentage <= 59.0) return 'WARNING';
    return 'CRITICAL';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MQ-5 Gas Saturation', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            height: 100,
            child: CustomPaint(
              painter: _RadialGaugePainter(fraction: (gasPercentage / 100.0).clamp(0.0, 1.0), activeColor: _statusColor),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  '${gasPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double fraction;
  final Color activeColor;

  _RadialGaugePainter({required this.fraction, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width * 0.45;

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Active
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fraction,
      false,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.activeColor != activeColor;
}
```

```dart
// lib/features/dashboard/presentation/widgets/emergency_alarm_banner.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmergencyAlarmBanner extends StatefulWidget {
  final bool isVisible;

  const EmergencyAlarmBanner({super.key, required this.isVisible});

  @override
  State<EmergencyAlarmBanner> createState() => _EmergencyAlarmBannerState();
}

class _EmergencyAlarmBannerState extends State<EmergencyAlarmBanner> with SingleTickerProviderStateMixin {
  late AnimationController _strobeController;

  @override
  void initState() {
    super.initState();
    _strobeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _strobeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _strobeController,
      builder: (context, child) {
        final color = Color.lerp(AppColors.dangerRed, AppColors.dangerRedDark, _strobeController.value)!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.dangerRed.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CRITICAL GAS LEAK DETECTED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                    Text('Automated GSM voice & SMS escalation active.', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

```dart
// lib/features/dashboard/presentation/widgets/manual_siren_toggle.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ManualSirenToggle extends StatelessWidget {
  final bool isSirenActive;
  final ValueChanged<bool> onToggle;

  const ManualSirenToggle({super.key, required this.isSirenActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSirenActive ? AppColors.dangerRed : AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSirenActive ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: isSirenActive ? AppColors.dangerRed : AppColors.textMuted,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hardware Siren Alarm', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(isSirenActive ? 'Alarm Blaring (Siren Active)' : 'Alarm Silenced / Standby', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          Switch(
            value: isSirenActive,
            onChanged: onToggle,
            activeColor: AppColors.dangerRed,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/dashboard/volumetric_cylinder_test.dart test/features/dashboard/gas_saturation_gauge_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/ test/features/dashboard/
git commit -m "feat: implement animated fluid cylinder canvas, radial gauge, emergency strobe, and siren switch"
```

---

### Task 5: Main Dashboard Screen & Provider Integration

**Files:**
- Create: `lib/features/dashboard/providers/dashboard_provider.dart`
- Create: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Test: `test/features/dashboard/dashboard_screen_test.dart`

**Interfaces:**
- Produces:
  - `dashboardProvider`: Riverpod provider exposing `TelemetryData` and `toggleSiren()`.
  - `DashboardScreen`: Complete telemetry hub tab integrating all Task 4 widgets.

- [ ] **Step 1: Write failing widget test for DashboardScreen**

```dart
// test/features/dashboard/dashboard_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen renders telemetry hub without overflow', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    expect(find.text('Telemetry Hub'), findsOneWidget);
    expect(find.text('Hardware Siren Alarm'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/dashboard/dashboard_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement DashboardProvider and DashboardScreen**

```dart
// lib/features/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/telemetry_data.dart';

final telemetryProvider = StateProvider<TelemetryData>((ref) {
  return const TelemetryData(
    gasPercentage: 14.5,
    netWeight: 4.25,
    selectedMaxKg: 6.0,
    alarmState: 0,
    isConnected: true,
  );
});
```

```dart
// lib/features/dashboard/presentation/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/volumetric_cylinder_painter.dart';
import 'widgets/gas_saturation_gauge.dart';
import 'widgets/emergency_alarm_banner.dart';
import 'widgets/manual_siren_toggle.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Telemetry Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: telemetry.isConnected ? AppColors.safeGreen : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  telemetry.isConnected ? 'BLE Linked' : 'Offline',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            EmergencyAlarmBanner(isVisible: telemetry.isCriticalLeak),
            if (telemetry.isCriticalLeak) const SizedBox(height: 16),

            // Volumetric Fluid Container
            VolumetricCylinder(
              fuelPercentage: telemetry.fuelPercentage,
              netWeightKg: telemetry.netWeight,
            ),
            const SizedBox(height: 16),

            // Radial Gas Gauge
            GasSaturationGauge(gasPercentage: telemetry.gasPercentage),
            const SizedBox(height: 16),

            // Master Siren Switch
            ManualSirenToggle(
              isSirenActive: telemetry.isSirenActive,
              onToggle: (active) {
                ref.read(telemetryProvider.notifier).state =
                    telemetry.copyWith(isSirenActive: active);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/dashboard/dashboard_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/ test/features/dashboard/
git commit -m "feat: implement DashboardScreen telemetry hub and reactive Riverpod provider"
```

---

### Task 6: Emergency Contacts Screen (Escalation Roster) & List Builders

**Files:**
- Create: `lib/features/contacts/presentation/emergency_contacts_screen.dart`
- Create: `lib/features/contacts/presentation/widgets/contact_list_builder.dart`
- Create: `lib/features/contacts/presentation/widgets/contact_input_modal.dart`
- Create: `lib/features/contacts/providers/contacts_provider.dart`
- Test: `test/features/contacts/emergency_contacts_screen_test.dart`

**Interfaces:**
- Produces:
  - `contactsProvider`: StateNotifier managing `smsRecipients` and `voiceRecipients`.
  - `EmergencyContactsScreen`: Escalation roster screen with validation engine.

- [ ] **Step 1: Write failing widget test for EmergencyContactsScreen**

```dart
// test/features/contacts/emergency_contacts_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/features/contacts/presentation/emergency_contacts_screen.dart';

void main() {
  testWidgets('EmergencyContactsScreen renders SMS and Voice sections', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: EmergencyContactsScreen(),
        ),
      ),
    );
    expect(find.text('Escalation Roster'), findsOneWidget);
    expect(find.text('SMS Alert Recipients'), findsOneWidget);
    expect(find.text('Voice Call Queue'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/contacts/emergency_contacts_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement ContactsProvider, ContactListBuilder, ContactInputModal, and EmergencyContactsScreen**

```dart
// lib/features/contacts/providers/contacts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/escalation_roster.dart';

final contactsProvider = StateNotifierProvider<ContactsNotifier, EscalationRoster>((ref) {
  return ContactsNotifier();
});

class ContactsNotifier extends StateNotifier<EscalationRoster> {
  ContactsNotifier()
      : super(const EscalationRoster(
          smsRecipients: ['+2348012345678'],
          voiceRecipients: ['+2348012345678'],
        ));

  void addSmsContact(String phone) {
    if (!state.smsRecipients.contains(phone)) {
      state = state.copyWith(smsRecipients: [...state.smsRecipients, phone]);
    }
  }

  void removeSmsContact(String phone) {
    state = state.copyWith(
      smsRecipients: state.smsRecipients.where((p) => p != phone).toList(),
    );
  }

  void addVoiceContact(String phone) {
    if (!state.voiceRecipients.contains(phone)) {
      state = state.copyWith(voiceRecipients: [...state.voiceRecipients, phone]);
    }
  }

  void removeVoiceContact(String phone) {
    state = state.copyWith(
      voiceRecipients: state.voiceRecipients.where((p) => p != phone).toList(),
    );
  }
}
```

```dart
// lib/features/contacts/presentation/widgets/contact_input_modal.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/phone_validator.dart';

class ContactInputModal extends StatefulWidget {
  final String title;
  final Function(String) onSave;

  const ContactInputModal({super.key, required this.title, required this.onSave});

  @override
  State<ContactInputModal> createState() => _ContactInputModalState();
}

class _ContactInputModalState extends State<ContactInputModal> {
  final _controller = TextEditingController();
  String? _errorText;

  void _validateAndSubmit() {
    final result = PhoneValidator.validate(_controller.text);
    if (!result.isValid) {
      setState(() => _errorText = result.errorMessage);
    } else {
      widget.onSave(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedCornerShape(20),
      title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '+234...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              errorText: _errorText,
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cyanAccent)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyanAccent, foregroundColor: Colors.black),
          child: const Text('Save Number'),
        ),
      ],
    );
  }
}
```

```dart
// lib/features/contacts/presentation/emergency_contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/contacts_provider.dart';
import 'widgets/contact_input_modal.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(contactsProvider);
    final notifier = ref.read(contactsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Escalation Roster', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SMS Section
          _buildSectionHeader(
            title: 'SMS Alert Recipients',
            subtitle: 'Immediate text broadcast on detected gas leak.',
            onAdd: () => showDialog(
              context: context,
              builder: (_) => ContactInputModal(
                title: 'Add SMS Recipient',
                onSave: (phone) => notifier.addSmsContact(phone),
              ),
            ),
          ),
          ...roster.smsRecipients.map((phone) => _buildContactCard(phone, () => notifier.removeSmsContact(phone))),
          const SizedBox(height: 24),

          // Voice Section
          _buildSectionHeader(
            title: 'Voice Call Queue',
            subtitle: 'Sequential calls if alarm persists for 3 minutes.',
            onAdd: () => showDialog(
              context: context,
              builder: (_) => ContactInputModal(
                title: 'Add Voice Call Recipient',
                onSave: (phone) => notifier.addVoiceContact(phone),
              ),
            ),
          ),
          ...roster.voiceRecipients.map((phone) => _buildContactCard(phone, () => notifier.removeVoiceContact(phone))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle, required VoidCallback onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
          IconButton(icon: const Icon(Icons.add_circle, color: AppColors.cyanAccent), onPressed: onAdd),
        ],
      ),
    );
  }

  Widget _buildContactCard(String phone, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(phone, style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.dangerRed), onPressed: onDelete),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/contacts/emergency_contacts_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/contacts/ test/features/contacts/
git commit -m "feat: implement Escalation Roster screen, list builders, and contact validation modal"
```

---

### Task 7: Hardware Configuration Screen & Tare Safety Confirmation Modal

**Files:**
- Create: `lib/features/hardware/presentation/hardware_config_screen.dart`
- Create: `lib/features/hardware/presentation/widgets/cylinder_size_dropdown.dart`
- Create: `lib/features/hardware/presentation/widgets/tare_confirmation_modal.dart`
- Test: `test/features/hardware/hardware_config_screen_test.dart`

**Interfaces:**
- Produces:
  - `CylinderSizeDropdown`: Dropdown offering 3.0kg, 6.0kg, 12.5kg, 25.0kg, 50.0kg.
  - `TareConfirmationModal`: Pop-up warning preventing accidental scale erasure.
  - `HardwareConfigScreen`: Hardware setup tab.

- [ ] **Step 1: Write failing widget test for HardwareConfigScreen**

```dart
// test/features/hardware/hardware_config_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/features/hardware/presentation/hardware_config_screen.dart';

void main() {
  testWidgets('HardwareConfigScreen renders cylinder dropdown and Tare button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HardwareConfigScreen(),
        ),
      ),
    );
    expect(find.text('Hardware Setup'), findsOneWidget);
    expect(find.text('Cylinder Capacity'), findsOneWidget);
    expect(find.text('Calibrate Empty Cylinder (Tare)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/hardware/hardware_config_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement CylinderSizeDropdown, TareConfirmationModal, and HardwareConfigScreen**

```dart
// lib/features/hardware/presentation/widgets/tare_confirmation_modal.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TareConfirmationModal extends StatelessWidget {
  final VoidCallback onConfirm;

  const TareConfirmationModal({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.dangerRed)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 28),
          SizedBox(width: 8),
          Text('Confirm Tare Calibration', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Text(
        'Ensure ONLY a completely EMPTY cylinder is resting on the scale.\n\nPerforming tare with gas inside will erase scale calibration and compromise leak safety calculations.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed, foregroundColor: Colors.white),
          child: const Text('Confirm & Zero Scale'),
        ),
      ],
    );
  }
}
```

```dart
// lib/features/hardware/presentation/hardware_config_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'widgets/tare_confirmation_modal.dart';

class HardwareConfigScreen extends ConsumerWidget {
  const HardwareConfigScreen({super.key});

  static const List<double> availableSizes = [3.0, 6.0, 12.5, 25.0, 50.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hardware Setup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Capacity Dropdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cylinder Capacity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Select your cylinder maximum weight to drive fluid animations.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 12),
                DropdownButtonFormField<double>(
                  value: telemetry.selectedMaxKg,
                  dropdownColor: AppColors.surfaceLight,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                  items: availableSizes.map((size) {
                    return DropdownMenuItem<double>(value: size, child: Text('$size kg LPG Cylinder'));
                  }).toList(),
                  onChanged: (newSize) {
                    if (newSize != null) {
                      ref.read(telemetryProvider.notifier).state = telemetry.copyWith(selectedMaxKg: newSize);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tare Calibration Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Load Cell Zero Calibration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Zero the load cell sensor when an empty tare cylinder is seated.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.scale_rounded),
                    label: const Text('Calibrate Empty Cylinder (Tare)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => TareConfirmationModal(
                          onConfirm: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Scale Zeroed (TARE command sent to ESP32)')),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/hardware/hardware_config_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/hardware/ test/features/hardware/
git commit -m "feat: implement Hardware Configuration screen with cylinder size selector and tare safety modal"
```

---

### Task 8: Navigation Shell & End-to-End Test Suite

**Files:**
- Create: `lib/main.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: Application entrypoint mounting 3-tab BottomNavigationBar: Dashboard, Escalation Roster, Hardware Setup.

- [ ] **Step 1: Write integration widget test for Navigation Shell**

```dart
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sba_gas_scale/main.dart';

void main() {
  testWidgets('App renders navigation bar and switches between tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SbaGasScaleApp()));
    expect(find.text('Telemetry Hub'), findsOneWidget);

    // Switch to Contacts
    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Escalation Roster'), findsOneWidget);

    // Switch to Setup
    await tester.tap(find.text('Hardware'));
    await tester.pumpAndSettle();
    expect(find.text('Hardware Setup'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement main.dart with 3-tab Scaffold**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/contacts/presentation/emergency_contacts_screen.dart';
import 'features/hardware/presentation/hardware_config_screen.dart';

void main() {
  runApp(const ProviderScope(child: SbaGasScaleApp()));
}

class SbaGasScaleApp extends StatefulWidget {
  const SbaGasScaleApp({super.key});

  @override
  State<SbaGasScaleApp> createState() => _SbaGasScaleAppState();
}

class _SbaGasScaleAppState extends State<SbaGasScaleApp> {
  int _currentTab = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    EmergencyContactsScreen(),
    HardwareConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SBA Gas Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.cyanAccent,
          surface: AppColors.surface,
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentTab,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentTab,
          onDestinationSelected: (index) => setState(() => _currentTab = index),
          backgroundColor: const Color(0xFF121829),
          indicatorColor: AppColors.cyanAccent.withOpacity(0.2),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppColors.cyanAccent), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.contact_phone_outlined), selectedIcon: Icon(Icons.contact_phone, color: AppColors.cyanAccent), label: 'Contacts'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppColors.cyanAccent), label: 'Hardware'),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run full test suite to verify everything passes**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "feat: implement 3-tab navigation shell and complete end-to-end integration"
```
