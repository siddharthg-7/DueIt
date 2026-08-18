import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Stitch Design System Typography Tokens for DueIt
abstract class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 38,
        height: 44 / 38,
        letterSpacing: -0.02 * 38,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 26,
        height: 34 / 26,
        letterSpacing: -0.01 * 26,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 22,
        height: 30 / 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 17,
        height: 23 / 17,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14.5,
        height: 20 / 14.5,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13.5,
        height: 19 / 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13.5,
        height: 19 / 13.5,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11.5,
        height: 15 / 11.5,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
      );
}
