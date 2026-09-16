import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sba_gas_scale/main.dart';

void main() {
  testWidgets('App renders navigation bar and switches between tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SbaGasScaleApp()));
    expect(find.text('Telemetry Hub'), findsOneWidget);

    // Switch to Contacts
    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Escalation Roster'), findsOneWidget);

    // Switch to Setup
    await tester.tap(find.text('Hardware'));
    await tester.pumpAndSettle();
    expect(find.text('Hardware Setup'), findsOneWidget);
  });
}
