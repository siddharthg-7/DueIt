import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/date_formatter.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String label;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label = 'Due Date',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: AppColors.onPrimary,
                  onSurface: AppColors.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != selectedDate) {
          onDateSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatDisplayDate(selectedDate),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
