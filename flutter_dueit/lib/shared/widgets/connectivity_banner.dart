import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/services/connectivity_service.dart';

/// Subtle, non-intrusive connectivity status indicator pill/banner.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStateProvider);

    final state = connectivityAsync.value ??
        ref.watch(connectivityServiceProvider).currentState;

    if (state.message == null || state.message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isOffline = state.isOffline;

    final bgColor = isOffline
        ? const Color(0xFFFFF8E1) // Soft amber
        : const Color(0xFFE8F5E9); // Soft mint/green

    final textColor = isOffline
        ? const Color(0xFF8D6E63) // Warm amber-brown
        : const Color(0xFF2E7D32); // Deep forest green

    final iconData =
        isOffline ? Icons.cloud_off_outlined : Icons.cloud_done_outlined;
    final iconColor =
        isOffline ? const Color(0xFFF57F17) : const Color(0xFF388E3C);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color:
                isOffline ? const Color(0xFFFFE082) : const Color(0xFFA5D6A7),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              state.message!,
              style: AppTypography.labelSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
