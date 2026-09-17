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
