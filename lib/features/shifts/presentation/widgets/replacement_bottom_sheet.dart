import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_card.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/presentation/cubit/shifts_cubit.dart';

class ReplacementBottomSheet extends StatelessWidget {
  final String shiftId;
  final NeighborEntity originalNeighbor;

  const ReplacementBottomSheet({
    super.key,
    required this.shiftId,
    required this.originalNeighbor,
  });

  @override
  Widget build(BuildContext context) {
    context.read<ShiftsCubit>().loadReplacementCandidates(
      shiftId: shiftId,
      originalNeighborId: originalNeighbor.id,
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REEMPLAZAR A: ${originalNeighbor.fullName.toUpperCase()}',
            style: context.design.labelCaps,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Candidatos recomendados por equidad y descanso:',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.md),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.md),
          Expanded(
            child: BlocBuilder<ShiftsCubit, ShiftsState>(
              builder: (context, state) {
                if (state is ShiftsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ReplacementCandidatesLoaded) {
                  if (state.candidates.isEmpty) {
                    return const Center(child: Text('No hay candidatos elegibles disponibles.'));
                  }
                  return ListView.builder(
                    itemCount: state.candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = state.candidates[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: candidate.neighbor.operationalProfile == OperationalProfile.active
                                  ? context.colorScheme.primaryContainer
                                  : context.colorScheme.surfaceContainerHighest,
                              child: Text(candidate.neighbor.fullName[0], style: TextStyle(color: context.colorScheme.onSurface)),
                            ),
                            title: Text(candidate.neighbor.fullName, style: context.textTheme.bodyLarge),
                            subtitle: Text(
                              'Bal: ${candidate.neighbor.balance} • ${candidate.effectiveProfile.value}',
                              style: context.textTheme.bodySmall,
                            ),
                            trailing: AppButton.tertiary(
                              label: 'ASIGNAR',
                              onPressed: () => _confirmReplacement(context, candidate.neighbor, candidate.effectiveProfile),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is ShiftsError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const SizedBox();
              },
            ),
          ),
          const SizedBox(height: AppSizes.md),
          AppButton.secondary(
            label: 'DEJAR TURNO CON DÉFICIT',
            icon: Icons.person_off_outlined,
            onPressed: () => _confirmReplacement(context, null, OperationalProfile.support),
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  void _confirmReplacement(BuildContext context, NeighborEntity? substitute, OperationalProfile effectiveProfile) {
    context.showThemedDialog(
      title: const Text('Confirmar Cambio'),
      content: Text(substitute == null
          ? '¿Seguro que deseas dejar la vacante sin cubrir? El turno operará con déficit.'
          : '¿Confirmas la asignación de ${substitute.fullName} como refuerzo para esta guardia?'),
      actions: [
        AppButton.tertiary(
          label: 'CANCELAR',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'CONFIRMAR',
          onPressed: () {
            context.read<ShiftsCubit>().performSubstitution(
              shiftId: shiftId,
              originalNeighborId: originalNeighbor.id,
              substituteNeighborId: substitute?.id,
              effectiveProfile: effectiveProfile,
            );
            Navigator.pop(context); // Cierra diálogo
            Navigator.pop(context); // Cierra BottomSheet
          },
        ),
      ],
    );
  }
}
