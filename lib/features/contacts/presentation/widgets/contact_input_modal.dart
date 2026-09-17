import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/phone_validator.dart';

class ContactInputModal extends StatefulWidget {
  final String title;
  final Function(String) onSave;

  const ContactInputModal({super.key, required this.title, required this.onSave});

  @override
  State<ContactInputModal> createState() => _ContactInputModalState();
}

class _ContactInputModalState extends State<ContactInputModal> {
  final _controller = TextEditingController();
  String? _errorText;

  void _validateAndSubmit() {
    final result = PhoneValidator.validate(_controller.text);
    if (!result.isValid) {
      setState(() => _errorText = result.errorMessage);
    } else {
      widget.onSave(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '+234...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              errorText: _errorText,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cyanAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyanAccent,
            foregroundColor: Colors.black,
          ),
          child: const Text('Save Number'),
        ),
      ],
    );
  }
}
