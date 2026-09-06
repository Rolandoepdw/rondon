import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';
import '../../features/neighbors/domain/entities/neighbor.dart';

class AppNeighborTile extends StatelessWidget {
  final NeighborEntity neighbor;
  final VoidCallback onTap;

  const AppNeighborTile({
    super.key,
    required this.neighbor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    neighbor.fullName,
                    style: AppTextStyles.titleMd,
                  ),
                  Text(
                    neighbor.phone ?? 'Sin teléfono',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            _buildScore(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final bool isActive = neighbor.operationalProfile == OperationalProfile.activo;
    
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? Icons.shield : Icons.person,
            color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
            size: 24,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceContainer, width: 2),
            ),
            child: Icon(
              neighbor.gender == Gender.masculino ? Icons.male : Icons.female,
              size: 10,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScore() {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      alignment: Alignment.center,
      child: Text(
        neighbor.balance.toString(),
        style: AppTextStyles.scoreNum.copyWith(
          color: neighbor.balance < 0 ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }
}
