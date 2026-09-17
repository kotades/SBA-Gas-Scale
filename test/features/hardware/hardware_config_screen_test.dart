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

  testWidgets('HardwareConfigScreen renders Bluetooth ESP32 Link scanner and controls', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HardwareConfigScreen(),
        ),
      ),
    );

    // Verify Bluetooth Link section exists
    expect(find.text('Bluetooth ESP32 Link'), findsOneWidget);
    expect(find.text('Scan for ESP32'), findsOneWidget);
    expect(find.text('Demo Scale'), findsOneWidget);
    expect(find.text('DISCONNECTED'), findsOneWidget);

    // Connect Demo Scale
    await tester.tap(find.text('Demo Scale'));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify connection state updates
    expect(find.text('CONNECTED'), findsOneWidget);
    expect(find.text('MTU 512 Active'), findsOneWidget);
    expect(find.text('Disconnect Scale'), findsOneWidget);

    // Disconnect Scale
    await tester.tap(find.text('Disconnect Scale'));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify reverts to disconnected
    expect(find.text('DISCONNECTED'), findsOneWidget);
    expect(find.text('Scan for ESP32'), findsOneWidget);
  });
}
