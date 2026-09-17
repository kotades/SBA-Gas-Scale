import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ble/ble_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/providers/dashboard_provider.dart';

class BleScannerCard extends ConsumerStatefulWidget {
  const BleScannerCard({super.key});

  @override
  ConsumerState<BleScannerCard> createState() => _BleScannerCardState();
}

class _BleScannerCardState extends ConsumerState<BleScannerCard> {
  String? _connectingDeviceId;

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final notifier = ref.read(telemetryProvider.notifier);
    final bleService = ref.watch(bleServiceProvider);

    final isScanningAsync = ref.watch(bleIsScanningProvider);
    final isScanning = isScanningAsync.value ?? false;

    final scanResultsAsync = ref.watch(bleScanResultsProvider);
    final scanResults = scanResultsAsync.value ?? [];

    final isConnected = telemetry.isConnected;
    final connectedDevice = bleService.connectedDevice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? AppColors.safeGreen.withValues(alpha: 0.4) : AppColors.cardBorder,
          width: isConnected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Icon, title, and connection badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.safeGreen.withValues(alpha: 0.15)
                      : AppColors.cyanAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching_rounded,
                  color: isConnected ? AppColors.safeGreen : AppColors.cyanAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bluetooth ESP32 Link',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? 'GATT Live Telemetry Stream Connected'
                          : (isScanning ? 'Scanning for nearby peripherals...' : 'Connect to SBA Scale hardware'),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.safeGreen.withValues(alpha: 0.2)
                      : (isScanning
                          ? AppColors.cyanAccent.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected
                        ? AppColors.safeGreen
                        : (isScanning ? AppColors.cyanAccent : Colors.grey.withValues(alpha: 0.5)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isScanning && !isConnected)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cyanAccent,
                        ),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? AppColors.safeGreen
                              : Colors.grey,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'CONNECTED' : (isScanning ? 'SCANNING' : 'DISCONNECTED'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isConnected
                            ? AppColors.safeGreen
                            : (isScanning ? AppColors.cyanAccent : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Connected State Details
          if (isConnected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.developer_board_rounded, color: AppColors.cyanAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          connectedDevice?.platformName.isNotEmpty == true
                              ? connectedDevice!.platformName
                              : 'SBA GAS DETECTOR (ESP32-C3)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.safeGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MTU 512 Active',
                          style: TextStyle(
                            color: AppColors.safeGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (connectedDevice != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Hardware ID: ${connectedDevice.remoteId.str}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.sensors, color: AppColors.safeGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Live Gas: ${telemetry.gasPercentage.toStringAsFixed(1)}% | Net: ${telemetry.netWeight.toStringAsFixed(2)} kg',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bluetooth_disabled_rounded, size: 18),
                label: const Text('Disconnect Scale'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  notifier.disconnect();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bluetooth device disconnected')),
                  );
                },
              ),
            ),
          ] else ...[
            // Disconnected View: Scan button & Quick Actions
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    icon: isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 20),
                    label: Text(isScanning ? 'Stop Scan' : 'Scan for ESP32'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (isScanning) {
                        notifier.stopScan();
                      } else {
                        notifier.startScan();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.smart_toy_outlined, size: 16),
                    label: const Text('Demo Scale'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyanAccent,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      notifier.connectDemo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Simulated ESP32 Scale connected for preview & testing'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Discovered Devices List
            if (scanResults.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discovered Peripherals (${scanResults.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isScanning)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.cyanAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...scanResults.map((result) {
                final device = result.device;
                final name = device.platformName.isNotEmpty
                    ? device.platformName
                    : (result.advertisementData.advName.isNotEmpty
                        ? result.advertisementData.advName
                        : 'Unknown BLE Device');
                final id = device.remoteId.str;
                final rssi = result.rssi;
                final isSbaTarget = name == BleConstants.deviceName ||
                    name.toUpperCase().contains('SBA') ||
                    name.toUpperCase().contains('ESP32') ||
                    result.advertisementData.serviceUuids.contains(Guid(BleConstants.serviceUuid));
                final isConnectingThis = _connectingDeviceId == id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSbaTarget
                          ? AppColors.cyanAccent.withValues(alpha: 0.6)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: isSbaTarget ? AppColors.cyanAccent : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSbaTarget) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyanAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'SCALE TARGET',
                                      style: TextStyle(
                                        color: AppColors.cyanAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$id  •  $rssi dBm',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSbaTarget ? AppColors.cyanAccent : const Color(0xFF374151),
                          foregroundColor: isSbaTarget ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(64, 34),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: isConnectingThis
                            ? null
                            : () async {
                                setState(() => _connectingDeviceId = id);
                                try {
                                  await notifier.connectDevice(device);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Connected to $name')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Connection failed: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _connectingDeviceId = null);
                                  }
                                }
                              },
                        child: isConnectingThis
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
            ] else if (isScanning) ...[
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanAccent),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Searching for SBA Scale & nearby BLE hardware...',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No devices discovered. Power on your ESP32 appliance and tap "Scan for ESP32".',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
