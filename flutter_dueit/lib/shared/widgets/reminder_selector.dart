import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';

/// Reusable Reminder Selector Widget for Add Due & Due Details
class ReminderSelector extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final List<String> options;

  const ReminderSelector({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    this.options = const [
      'On due date',
      '1 day before',
      '2 days before',
      '3 days before',
      '1 week before',
      'None',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Reminder',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected =
                selectedValue.toLowerCase() == option.toLowerCase();
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option);
                }
              },
              labelStyle: isSelected
                  ? AppTypography.labelSmall.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    )
                  : AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              selectedColor: AppColors.primaryContainer,
              backgroundColor: AppColors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : AppColors.outlineVariant,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            );
          }).toList(),
        ),
      ],
    );
  }
}
