import 'dart:convert';
import '../models/escalation_roster.dart';

/// Serializes high-level user actions, calibration routines, and escalation rosters
/// into the unified JSON protocol accepted by the ESP32-C3 firmware.
class BleCommandSerializer {
  /// Tare / Zero the load cell scale.
  static String serializeTare() {
    return jsonEncode({'cmd': 'TARE'});
  }

  /// Remotely trigger or silence the physical hardware siren/buzzer.
  static String serializeSiren(bool state) {
    return jsonEncode({'cmd': 'SIREN', 'state': state});
  }

  /// Set the cylinder capacity in kilograms (e.g. 3.0, 6.0, 12.5, 25.0, 50.0).
  static String serializeSetMax(double maxKg) {
    return jsonEncode({'cmd': 'SET_MAX', 'max_kg': maxKg});
  }

  /// Transmit the dual SMS and Voice escalation rosters.
  static String serializeSyncRoster(EscalationRoster roster) {
    return jsonEncode({
      'cmd': 'SYNC_ROSTER',
      'sms': roster.smsRecipients,
      'voice': roster.voiceRecipients,
    });
  }

  /// Full state synchronization package for initial connection handshake.
  static String serializeSyncAll({
    required double maxKg,
    required bool sirenState,
    required EscalationRoster roster,
  }) {
    return jsonEncode({
      'cmd': 'SYNC_ALL',
      'max_kg': maxKg,
      'siren': sirenState,
      'sms': roster.smsRecipients,
      'voice': roster.voiceRecipients,
    });
  }
}
