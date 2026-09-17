import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ManualSirenToggle extends StatelessWidget {
  final bool isSirenActive;
  final ValueChanged<bool> onToggle;

  const ManualSirenToggle({
    super.key,
    required this.isSirenActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSirenActive ? AppColors.dangerRed : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSirenActive ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: isSirenActive ? AppColors.dangerRed : AppColors.textMuted,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hardware Siren Alarm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isSirenActive
                        ? 'Alarm Blaring (Siren Active)'
                        : 'Alarm Silenced / Standby',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isSirenActive,
            onChanged: onToggle,
            activeThumbColor: AppColors.dangerRed,
          ),
        ],
      ),
    );
  }
}
