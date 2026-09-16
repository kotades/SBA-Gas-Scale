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
