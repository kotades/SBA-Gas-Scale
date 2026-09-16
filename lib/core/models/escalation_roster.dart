/// Collection of phone numbers designated for emergency SMS and voice escalation.
class EscalationRoster {
  final List<String> smsRecipients;
  final List<String> voiceRecipients;

  const EscalationRoster({
    this.smsRecipients = const [],
    this.voiceRecipients = const [],
  });

  EscalationRoster copyWith({
    List<String>? smsRecipients,
    List<String>? voiceRecipients,
  }) {
    return EscalationRoster(
      smsRecipients: smsRecipients ?? this.smsRecipients,
      voiceRecipients: voiceRecipients ?? this.voiceRecipients,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EscalationRoster &&
          runtimeType == other.runtimeType &&
          _listEquals(smsRecipients, other.smsRecipients) &&
          _listEquals(voiceRecipients, other.voiceRecipients);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(smsRecipients),
        Object.hashAll(voiceRecipients),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
