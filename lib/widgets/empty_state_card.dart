import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class InlineLoadingCard extends StatelessWidget {
  const InlineLoadingCard({super.key, this.label = 'Loading...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class InlineErrorCard extends StatelessWidget {
  const InlineErrorCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              // Icons.cloud_off_outlined,
              Icons.message,
              size: 28,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 10),
            const Text(
              'No chat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            // const SizedBox(height: 4),
            // Text(
            //   message,
            //   textAlign: TextAlign.center,
            //   style: const TextStyle(
            //     fontSize: 13,
            //     color: AppColors.textSecondary,
            //     height: 1.4,
            //   ),
            // ),
            // if (onRetry != null) ...[
            //   const SizedBox(height: 12),
            //   TextButton(onPressed: onRetry, child: const Text('Try again')),
            // ],
          ],
        ),
      ),
    );
  }
}

String friendlyErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('connection')) {
    return 'Please check your internet connection and try again.';
  }
  if (text.contains('401')) {
    return 'Your session expired. Please sign in again.';
  }
  return 'We could not load this right now. Please try again.';
}
