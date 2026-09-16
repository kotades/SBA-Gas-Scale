import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sba_gas_scale/core/theme/app_colors.dart';
import 'package:sba_gas_scale/core/theme/app_typography.dart';

void main() {
  test('AppColors defines required safety and brand palette', () {
    expect(AppColors.background, const Color(0xFF090D16));
    expect(AppColors.surface, const Color(0xFF161E31));
    expect(AppColors.safeGreen, const Color(0xFF10B981));
    expect(AppColors.warningAmber, const Color(0xFFF59E0B));
    expect(AppColors.dangerRed, const Color(0xFFEF4444));
    expect(AppColors.cyanAccent, const Color(0xFF00F2FE));
  });

  test('AppTypography defines expected text styles', () {
    expect(AppTypography.heading1.fontSize, 22);
    expect(AppTypography.digitalValue.fontFamily, 'monospace');
  });
}
