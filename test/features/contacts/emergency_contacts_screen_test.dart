import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/features/contacts/presentation/emergency_contacts_screen.dart';

void main() {
  testWidgets('EmergencyContactsScreen renders SMS and Voice sections', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: EmergencyContactsScreen(),
        ),
      ),
    );
    expect(find.text('Escalation Roster'), findsOneWidget);
    expect(find.text('SMS Alert Recipients'), findsOneWidget);
    expect(find.text('Voice Call Queue'), findsOneWidget);
  });
}
