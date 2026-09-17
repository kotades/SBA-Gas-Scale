import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmergencyAlarmBanner extends StatefulWidget {
  final bool isVisible;

  const EmergencyAlarmBanner({super.key, required this.isVisible});

  @override
  State<EmergencyAlarmBanner> createState() => _EmergencyAlarmBannerState();
}

class _EmergencyAlarmBannerState extends State<EmergencyAlarmBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _strobeController;

  @override
  void initState() {
    super.initState();
    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _strobeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _strobeController,
      builder: (context, child) {
        final color = Color.lerp(
          AppColors.dangerRed,
          AppColors.dangerRedDark,
          _strobeController.value,
        )!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.dangerRed.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRITICAL GAS LEAK DETECTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Automated GSM voice & SMS escalation active.',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
