import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/shared/widgets/primary_button.dart';

/// DueIt Welcome / Onboarding Screen (matches Google Stitch design)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Ambient depth background circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiary.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main Canvas
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Header
                  Text(
                    'DueIt',
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage cash flow\nwith clarity.',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.onSurface,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  // Value Proposition Cards
                  _buildValueCard(
                    icon: Icons.payments_rounded,
                    iconBg: AppColors.primaryContainer,
                    iconFg: AppColors.onPrimaryContainer,
                    title: "Track money you're owed",
                    description:
                        'Keep all your outstanding dues and clients in one place.',
                  ),
                  const SizedBox(height: 12),
                  _buildValueCard(
                    icon: Icons.today_rounded,
                    iconBg: AppColors.secondaryContainer,
                    iconFg: AppColors.onSecondaryContainer,
                    title: 'Know what to collect today',
                    description:
                        'Focus on daily priorities to maintain healthy cash flow.',
                  ),
                  const SizedBox(height: 12),
                  _buildValueCard(
                    icon: Icons.notifications_active_rounded,
                    iconBg: AppColors.tertiaryFixed,
                    iconFg: AppColors.onTertiaryFixed,
                    title: 'Get reminders before due',
                    description:
                        'Automated nudges and WhatsApp alerts so nothing slips.',
                  ),

                  const Spacer(),

                  // Actions
                  PrimaryButton(
                    label: 'Get Started',
                    icon: Icons.arrow_forward,
                    onPressed: () =>
                        context.push('${RouteNames.login}?tab=register'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              context.push('${RouteNames.login}?tab=signin'),
                          child: Text(
                            'Sign In',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconFg, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
