import 'package:flutter/material.dart';
import 'package:rondon/core/theme/app_sizes.dart';

enum AppButtonType { primary, secondary, tertiary }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  }) : type = AppButtonType.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  }) : type = AppButtonType.secondary;

  const AppButton.tertiary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  }) : type = AppButtonType.tertiary;

  @override
  Widget build(BuildContext context) {
    if (type == AppButtonType.primary) {
      return _wrap(
        ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(),
        ),
      );
    } else if (type == AppButtonType.secondary) {
      return _wrap(
        OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(),
        ),
      );
    } else {
      return _wrap(
        TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(),
        ),
      );
    }
  }

  Widget _wrap(Widget child) {
    return SizedBox(
      height: 48,
      child: child,
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        width: AppSizes.lg,
        height: AppSizes.lg,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.lg),
          const SizedBox(width: AppSizes.sm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
