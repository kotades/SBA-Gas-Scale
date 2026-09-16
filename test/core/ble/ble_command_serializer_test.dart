import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/ble/ble_command_serializer.dart';
import 'package:sba_gas_scale/core/models/escalation_roster.dart';

void main() {
  group('BleCommandSerializer', () {
    test('serializes tare command accurately', () {
      final jsonStr = BleCommandSerializer.serializeTare();
      final map = jsonDecode(jsonStr);
      expect(map['cmd'], 'TARE');
    });

    test('serializes siren toggle command', () {
      final onStr = BleCommandSerializer.serializeSiren(true);
      expect(jsonDecode(onStr), {'cmd': 'SIREN', 'state': true});

      final offStr = BleCommandSerializer.serializeSiren(false);
      expect(jsonDecode(offStr), {'cmd': 'SIREN', 'state': false});
    });

    test('serializes cylinder capacity command', () {
      final str = BleCommandSerializer.serializeSetMax(12.5);
      expect(jsonDecode(str), {'cmd': 'SET_MAX', 'max_kg': 12.5});
    });

    test('serializes escalation roster with multiple SMS and voice numbers', () {
      const roster = EscalationRoster(
        smsRecipients: ['+2348011111111', '+2348022222222'],
        voiceRecipients: ['+2348033333333'],
      );
      final jsonStr = BleCommandSerializer.serializeSyncRoster(roster);
      final map = jsonDecode(jsonStr);
      expect(map['cmd'], 'SYNC_ROSTER');
      expect(map['sms'], ['+2348011111111', '+2348022222222']);
      expect(map['voice'], ['+2348033333333']);
    });

    test('serializes full handshake sync payload', () {
      const roster = EscalationRoster(
        smsRecipients: ['+2348012345678'],
        voiceRecipients: ['+2348099998888'],
      );
      final jsonStr = BleCommandSerializer.serializeSyncAll(
        maxKg: 6.0,
        sirenState: false,
        roster: roster,
      );
      final map = jsonDecode(jsonStr);
      expect(map['cmd'], 'SYNC_ALL');
      expect(map['max_kg'], 6.0);
      expect(map['siren'], false);
      expect(map['sms'], ['+2348012345678']);
      expect(map['voice'], ['+2348099998888']);
    });
  });
}
