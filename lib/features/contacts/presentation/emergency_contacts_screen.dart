import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/contacts_provider.dart';
import 'widgets/contact_input_modal.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(contactsProvider);
    final notifier = ref.read(contactsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Escalation Roster',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SMS Section
          _buildSectionHeader(
            title: 'SMS Alert Recipients',
            subtitle: 'Immediate text broadcast on detected gas leak.',
            onAdd: () => showDialog(
              context: context,
              builder: (_) => ContactInputModal(
                title: 'Add SMS Recipient',
                onSave: (phone) => notifier.addSmsContact(phone),
              ),
            ),
          ),
          ...roster.smsRecipients.map(
            (phone) => _buildContactCard(phone, () => notifier.removeSmsContact(phone)),
          ),
          const SizedBox(height: 24),

          // Voice Section
          _buildSectionHeader(
            title: 'Voice Call Queue',
            subtitle: 'Sequential calls if alarm persists for 3 minutes.',
            onAdd: () => showDialog(
              context: context,
              builder: (_) => ContactInputModal(
                title: 'Add Voice Call Recipient',
                onSave: (phone) => notifier.addVoiceContact(phone),
              ),
            ),
          ),
          ...roster.voiceRecipients.map(
            (phone) => _buildContactCard(phone, () => notifier.removeVoiceContact(phone)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.cyanAccent),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String phone, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            phone,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.dangerRed),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
