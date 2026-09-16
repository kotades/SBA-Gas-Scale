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
