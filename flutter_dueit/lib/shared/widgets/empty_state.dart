import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'primary_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: PrimaryButton(
                  text: actionText!,
                  onPressed: onAction,
                  height: 44,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
