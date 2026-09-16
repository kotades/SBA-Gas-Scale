import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/escalation_roster.dart';

final contactsProvider = StateNotifierProvider<ContactsNotifier, EscalationRoster>((ref) {
  return ContactsNotifier();
});

class ContactsNotifier extends StateNotifier<EscalationRoster> {
  ContactsNotifier()
      : super(const EscalationRoster(
          smsRecipients: ['+2348012345678'],
          voiceRecipients: ['+2348012345678'],
        ));

  void addSmsContact(String phone) {
    if (!state.smsRecipients.contains(phone)) {
      state = state.copyWith(smsRecipients: [...state.smsRecipients, phone]);
    }
  }

  void removeSmsContact(String phone) {
    state = state.copyWith(
      smsRecipients: state.smsRecipients.where((p) => p != phone).toList(),
    );
  }

  void addVoiceContact(String phone) {
    if (!state.voiceRecipients.contains(phone)) {
      state = state.copyWith(voiceRecipients: [...state.voiceRecipients, phone]);
    }
  }

  void removeVoiceContact(String phone) {
    state = state.copyWith(
      voiceRecipients: state.voiceRecipients.where((p) => p != phone).toList(),
    );
  }
}
