import 'package:flutter/material.dart';
import 'package:dueit/core/theme/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onIndexChanged,
        height: 72,
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.secondaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.onSecondaryContainer),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group, color: AppColors.onSecondaryContainer),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.onSecondaryContainer),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large, color: AppColors.onSecondaryContainer),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
