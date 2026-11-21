import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text_styles.dart';

extension ThemeContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  /// Direct access to our custom "Monolith Deep" design tokens
  AppDesignExtension get design => theme.extension<AppDesignExtension>()!;

  /// Show a themed dialog with Monolith Deep Level 2 surface
  Future<T?> showThemedDialog<T>({
    required Widget title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: this,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        ),
        title: DefaultTextStyle(
          style: AppTextStyles.titleMd,
          child: title,
        ),
        content: DefaultTextStyle(
          style: AppTextStyles.bodyLg,
          child: content,
        ),
        actions: actions,
      ),
    );
  }

  /// Show a themed bottom sheet with Monolith Deep Level 2 surface
  Future<T?> showThemedBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: child,
      ),
    );
  }
}
