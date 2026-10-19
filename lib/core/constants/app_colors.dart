import 'package:flutter/material.dart';

class AppColors {
  // OLED Pitch Black Theme (FRD SEC-08 & SEC-09: #090D16)
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF101524);
  static const Color surfaceLight = Color(0xFF161E33);
  static const Color card = Color(0xFF13192B);
  static const Color border = Color(0xFF1E293B);
  static const Color divider = Color(0xFF182236);

  // High-Contrast Neon HUD Accents
  static const Color cyan = Color(0xFF00E5FF);       // Armed / Ready
  static const Color green = Color(0xFF00E676);      // Running / Valid
  static const Color yellow = Color(0xFFFFD600);     // Staging / Calibrating
  static const Color red = Color(0xFFFF1744);        // False Start / Invalid / Cancelled
  static const Color purple = Color(0xFFD500F9);     // Finished
  static const Color orange = Color(0xFFFF6D00);     // GPS Warning / Waiting

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textGlow = Color(0xFFE2E8F0);

  // Status-Specific Colors
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'IDLE':
      case 'GPS LOCK':
        return orange;
      case 'STAGING':
        return yellow;
      case 'ARMED':
      case 'READY':
        return cyan;
      case 'RUNNING':
        return green;
      case 'FINISHED':
        return purple;
      case 'CANCELLED':
      case 'FALSE START':
        return red;
      default:
        return textSecondary;
    }
  }
}
