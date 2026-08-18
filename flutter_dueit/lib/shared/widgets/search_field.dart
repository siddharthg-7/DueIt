import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search by name or batch...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          filled: false,
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
                  onPressed: () {
                    controller.clear();
                    if (onClear != null) onClear!();
                    if (onChanged != null) onChanged!('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
