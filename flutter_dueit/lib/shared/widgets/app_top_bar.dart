import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;
  final int unreadNotificationsCount;

  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.onProfile,
    this.onNotifications,
    this.unreadNotificationsCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : IconButton(
              icon: const Icon(Icons.account_circle, color: AppColors.primary),
              onPressed: onProfile,
            ),
      title: Text(
        title,
        style: AppTypography.headlineMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      actions: [
        if (onNotifications != null)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.primary),
                onPressed: onNotifications,
              ),
              if (unreadNotificationsCount > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          height: 1,
        ),
      ),
    );
  }
}
