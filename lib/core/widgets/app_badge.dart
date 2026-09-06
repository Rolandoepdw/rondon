import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_theme.dart';
import '../theme/theme_context_ext.dart';

enum AppBadgeType { info, success, warning, error }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;

  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.info,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.design.labelCaps.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getColor(BuildContext context) {
    switch (type) {
      case AppBadgeType.success:
        return Colors.greenAccent;
      case AppBadgeType.warning:
        return Colors.orangeAccent;
      case AppBadgeType.error:
        return context.colorScheme.error;
      case AppBadgeType.info:
      default:
        return context.colorScheme.primary;
    }
  }
}
