import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class VolumetricCylinder extends StatefulWidget {
  final double fuelPercentage;
  final double netWeightKg;

  const VolumetricCylinder({
    super.key,
    required this.fuelPercentage,
    required this.netWeightKg,
  });

  @override
  State<VolumetricCylinder> createState() => _VolumetricCylinderState();
}

class _VolumetricCylinderState extends State<VolumetricCylinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return SizedBox(
          width: 220,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 320),
                painter: _CylinderPainter(
                  fuelFraction: (widget.fuelPercentage / 100.0).clamp(0.0, 1.0),
                  wavePhase: _waveController.value * 2 * math.pi,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.fuelPercentage.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${widget.netWeightKg.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 18,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'LPG REMAINING',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CylinderPainter extends CustomPainter {
  final double fuelFraction;
  final double wavePhase;

  _CylinderPainter({required this.fuelFraction, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Cylinder Outline Path (Collar + Tank + Base)
    final tankRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.18, w * 0.7, h * 0.72),
      const Radius.circular(32),
    );

    // Collar Shroud Handle
    final collarPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.06, w * 0.44, h * 0.14),
        const Radius.circular(12),
      ));

    // Draw Background Tank
    final bgPaint = Paint()..color = const Color(0xFF161E31);
    canvas.drawRRect(tankRect, bgPaint);
    canvas.drawPath(collarPath, Paint()..color = const Color(0xFF222C45));

    // Clip to Tank for Fluid Wave
    canvas.save();
    canvas.clipRRect(tankRect);

    final waterY = (h * 0.9) - ((h * 0.72) * fuelFraction);
    final wavePath = Path()..moveTo(0, waterY);

    for (double x = 0; x <= w; x += 4) {
      final y = waterY + 6 * math.sin((x / w * 2 * math.pi) + wavePhase);
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(w, h);
    wavePath.lineTo(0, h);
    wavePath.close();

    final fluidPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.cyanAccent, AppColors.blueAccent],
      ).createShader(Rect.fromLTWH(0, waterY, w, h - waterY));

    canvas.drawPath(wavePath, fluidPaint);
    canvas.restore();

    // Outline Borders
    final borderPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(tankRect, borderPaint);
    canvas.drawPath(collarPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CylinderPainter oldDelegate) =>
      oldDelegate.fuelFraction != fuelFraction || oldDelegate.wavePhase != wavePhase;
}
