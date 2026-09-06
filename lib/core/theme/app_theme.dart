import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.surfaceBase,
      
      // Typography
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display,
        headlineLarge: AppTextStyles.headlineLg,
        titleMedium: AppTextStyles.titleMd,
        bodyLarge: AppTextStyles.bodyLg,
        bodySmall: AppTextStyles.bodySm,
      ),

      // Components
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceBase,
        foregroundColor: AppColors.onSurface,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: AppTextStyles.titleMd,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          ),
          textStyle: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primaryContainer),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTextStyles.bodySm,
        hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceBase,
        indicatorColor: AppColors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return AppTextStyles.labelCaps.copyWith(
            color: isSelected ? AppColors.primary : AppColors.onSurfaceMuted,
            fontSize: 10,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
            size: 24,
          );
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceMuted,
        indicatorColor: AppColors.primary,
        labelStyle: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.bodySm,
      ),

      extensions: [
        AppDesignExtension(
          surfaceBase: AppColors.surfaceBase,
          accentGlow: AppColors.accentGlow,
          labelCaps: AppTextStyles.labelCaps,
          scoreNum: AppTextStyles.scoreNum,
        ),
      ],
    );
  }
}

/// Custom Extension for values not present in standard ThemeData
class AppDesignExtension extends ThemeExtension<AppDesignExtension> {
  final Color surfaceBase;
  final Color accentGlow;
  final TextStyle labelCaps;
  final TextStyle scoreNum;

  const AppDesignExtension({
    required this.surfaceBase,
    required this.accentGlow,
    required this.labelCaps,
    required this.scoreNum,
  });

  @override
  ThemeExtension<AppDesignExtension> copyWith({
    Color? surfaceBase,
    Color? accentGlow,
    TextStyle? labelCaps,
    TextStyle? scoreNum,
  }) {
    return AppDesignExtension(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      accentGlow: accentGlow ?? this.accentGlow,
      labelCaps: labelCaps ?? this.labelCaps,
      scoreNum: scoreNum ?? this.scoreNum,
    );
  }

  @override
  ThemeExtension<AppDesignExtension> lerp(
    ThemeExtension<AppDesignExtension>? other,
    double t,
  ) {
    if (other is! AppDesignExtension) return this;
    return AppDesignExtension(
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      labelCaps: TextStyle.lerp(labelCaps, other.labelCaps, t)!,
      scoreNum: TextStyle.lerp(scoreNum, other.scoreNum, t)!,
    );
  }
}
