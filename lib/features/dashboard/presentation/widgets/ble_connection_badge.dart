import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BleConnectionBadge extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onConnectTap;

  const BleConnectionBadge({
    super.key,
    required this.isConnected,
    this.onConnectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.safeGreen : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Linked: SBA GAS DETECTOR' : 'Offline',
            style: TextStyle(
              color: isConnected ? AppColors.safeGreen : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isConnected && onConnectTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onConnectTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cyanAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Scan / Connect',
                  style: TextStyle(
                    color: AppColors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
