import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final String? label;
  final String symbol;
  final Color? amountColor;
  final double fontSize;
  final CrossAxisAlignment crossAxisAlignment;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.label,
    this.symbol = '₹',
    this.amountColor,
    this.fontSize = 36,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          CurrencyFormatter.format(amount, symbol: symbol),
          style: AppTypography.displayLarge.copyWith(
            fontSize: fontSize,
            color: amountColor ?? AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
