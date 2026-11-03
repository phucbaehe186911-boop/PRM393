import 'package:flutter/material.dart';

/// Bảng màu chính của SportZone theo ui-conventions.md
class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF4F4F5);

  // Text
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFFA1A1AA);

  // Border
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderStrong = Color(0xFFD4D4D8);

  // Primary accent
  static const Color primary = Color(0xFF15803D);
  static const Color primaryLight = Color(0xFFF0FDF4);
  static const Color primaryMuted = Color(0xFF86EFAC);

  // Peak hours accent
  static const Color peak = Color(0xFFEA580C);
  static const Color peakLight = Color(0xFFFFFBEB);
  static const Color peakBorder = Color(0xFFFCD34D);

  // Slot states
  static const Color slotLocked = Color(0xFFFEF3C7);
  static const Color slotLockedBorder = Color(0xFFD97706);

  // Status
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  // Dark variants
  static const Color borderDark = Color(0xFF27272A);
}
