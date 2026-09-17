/// Safety severity status based on ambient gas saturation and fuel levels.
enum SafetyStatus {
  safe,
  warning,
  critical,
}

/// Immutable data snapshot representing current appliance telemetry and connection status.
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

  /// Computes remaining fuel percentage relative to the selected cylinder capacity.
  double get fuelPercentage {
    if (selectedMaxKg <= 0) return 0.0;
    return ((netWeight / selectedMaxKg) * 100.0).clamp(0.0, 100.0);
  }

  /// True if gas sensor exceeds critical threshold (60%) or hardware enters alarm mode (state 2).
  bool get isCriticalLeak => alarmState == 2 || gasPercentage >= 60.0;

  /// True if remaining liquid gas is under 1.0 kg reserve threshold.
  bool get isLowFuel => netWeight < 1.0;

  /// Categorical safety state driving UI color shifts and warning banners.
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TelemetryData &&
          runtimeType == other.runtimeType &&
          gasPercentage == other.gasPercentage &&
          netWeight == other.netWeight &&
          alarmState == other.alarmState &&
          isConnected == other.isConnected &&
          selectedMaxKg == other.selectedMaxKg &&
          isSirenActive == other.isSirenActive;

  @override
  int get hashCode =>
      gasPercentage.hashCode ^
      netWeight.hashCode ^
      alarmState.hashCode ^
      isConnected.hashCode ^
      selectedMaxKg.hashCode ^
      isSirenActive.hashCode;
}
