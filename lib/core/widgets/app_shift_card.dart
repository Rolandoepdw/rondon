import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

class AppShiftCard extends StatelessWidget {
  final String title;
  final String timeRange;
  final List<String>? details;
  final List<Widget>? badges;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final Widget? trailing;
  final bool isDisabled;

  const AppShiftCard({
    super.key,
    required this.title,
    required this.timeRange,
    this.details,
    this.badges,
    this.actions,
    this.onMenuPressed,
    this.trailing,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: AppCard(
        margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSizes.md),
            _buildDetails(context),
            if (badges != null && badges!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.xs,
                children: badges!,
              ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              const Divider(height: 1, color: AppColors.outlineVariant),
              const SizedBox(height: AppSizes.md),
              Row(
                children: actions!.map((a) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                  child: a,
                ))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMd,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null)
          trailing!
        else if (onMenuPressed != null)
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.more_vert, size: AppSizes.lg),
            color: AppColors.onSurfaceVariant,
          ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Column(
      children: [
        _DetailItem(icon: Icons.schedule, text: timeRange, isHighlight: true),
        if (details != null)
          ...details!.map((d) => _DetailItem(icon: Icons.info_outline, text: d)),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isHighlight;

  const _DetailItem({
    required this.icon,
    required this.text,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isHighlight ? AppColors.primary : AppColors.onSurfaceMuted,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              text,
              style: isHighlight ? AppTextStyles.bodyLg : AppTextStyles.bodySm,
            ),
          ),
        ],
      ),
    );
  }
}
