import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/models/telemetry_data.dart';

void main() {
  group('TelemetryData', () {
    test('computes fuelPercentage correctly clamped between 0 and 100', () {
      const data = TelemetryData(netWeight: 6.25, selectedMaxKg: 12.5);
      expect(data.fuelPercentage, 50.0);

      const overflow = TelemetryData(netWeight: 15.0, selectedMaxKg: 12.5);
      expect(overflow.fuelPercentage, 100.0);

      const negative = TelemetryData(netWeight: -1.0, selectedMaxKg: 12.5);
      expect(negative.fuelPercentage, 0.0);
    });

    test('determines safety levels accurately', () {
      expect(const TelemetryData(gasPercentage: 15.0, netWeight: 5.0).safetyStatus, SafetyStatus.safe);
      expect(const TelemetryData(gasPercentage: 45.0, netWeight: 5.0).safetyStatus, SafetyStatus.warning);
      expect(const TelemetryData(gasPercentage: 65.0, netWeight: 5.0).safetyStatus, SafetyStatus.critical);
      expect(const TelemetryData(alarmState: 2, netWeight: 5.0).safetyStatus, SafetyStatus.critical);
    });

    test('detects low fuel correctly under 1.0 kg', () {
      expect(const TelemetryData(netWeight: 0.8).isLowFuel, isTrue);
      expect(const TelemetryData(netWeight: 1.5).isLowFuel, isFalse);
    });
  });
}
