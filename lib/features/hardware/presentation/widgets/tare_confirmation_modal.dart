import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TareConfirmationModal extends StatelessWidget {
  final VoidCallback onConfirm;

  const TareConfirmationModal({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.dangerRed),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 28),
          SizedBox(width: 8),
          Text(
            'Confirm Tare Calibration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'Ensure ONLY a completely EMPTY cylinder is resting on the scale.\n\nPerforming tare with gas inside will erase scale calibration and compromise leak safety calculations.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dangerRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm & Zero Scale'),
        ),
      ],
    );
  }
}
