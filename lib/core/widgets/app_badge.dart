import 'package:flutter/material.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';

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
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color.withAlpha(76)),
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
        return context.colorScheme.primary;
    }
  }
}
