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
