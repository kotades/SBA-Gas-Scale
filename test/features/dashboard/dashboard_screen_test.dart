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
