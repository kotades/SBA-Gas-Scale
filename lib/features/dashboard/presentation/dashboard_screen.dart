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
        title: const Text(
          'Telemetry Hub',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: telemetry.isConnected
                        ? AppColors.safeGreen
                        : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  telemetry.isConnected ? 'BLE Linked' : 'Offline',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
