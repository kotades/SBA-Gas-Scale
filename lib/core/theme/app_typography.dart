import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Standard typography hierarchy for the SBA Gas Detector app.
class AppTypography {
  static const TextStyle heading1 = TextStyle(
    color: AppColors.textMain,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    color: AppColors.textMain,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle digitalValue = TextStyle(
    color: AppColors.textMain,
    fontSize: 24,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle digitalValueSmall = TextStyle(
    color: AppColors.cyanAccent,
    fontSize: 18,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
  );
}
