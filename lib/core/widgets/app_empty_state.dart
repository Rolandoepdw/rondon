import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.onSurfaceMuted.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            title,
            style: AppTextStyles.titleMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            description,
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSizes.xl),
            action!,
          ],
        ],
      ),
    );
  }
}
