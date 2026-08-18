import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color? textColor;
  final Color? borderColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          side: BorderSide(
            color: borderColor ?? AppColors.outlineVariant,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textColor ?? AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: AppTypography.labelLarge.copyWith(
                color: textColor ?? AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
