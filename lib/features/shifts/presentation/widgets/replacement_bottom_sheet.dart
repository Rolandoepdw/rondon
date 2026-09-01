import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';

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
    // Iniciamos la carga de candidatos inmediatamente
    context.read<ShiftsBloc>().add(LoadReplacementCandidates(
      shiftId: shiftId,
      originalNeighborId: originalNeighbor.id,
    ));

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reemplazar a: ${originalNeighbor.fullName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Candidatos recomendados por equidad y descanso:'),
          const Divider(),
          Expanded(
            child: BlocBuilder<ShiftsBloc, ShiftsState>(
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
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: candidate.neighbor.operationalProfile == OperationalProfile.activo 
                                ? Colors.green.shade50 
                                : Colors.orange.shade50,
                            child: Text(candidate.neighbor.fullName[0]),
                          ),
                          title: Text(candidate.neighbor.fullName),
                          subtitle: Text('Balance: ${candidate.neighbor.balance} | Perfil: ${candidate.effectiveProfile.value}'),
                          trailing: FilledButton.tonal(
                            onPressed: () => _confirmReplacement(context, candidate.neighbor, candidate.effectiveProfile),
                            child: const Text('Asignar'),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmReplacement(context, null, OperationalProfile.apoyo), // Caso déficit
              icon: const Icon(Icons.person_off_outlined),
              label: const Text('Dejar turno con déficit (Sin reemplazo)'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReplacement(BuildContext context, NeighborEntity? substitute, OperationalProfile effectiveProfile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Cambio'),
        content: Text(substitute == null 
            ? '¿Seguro que deseas dejar la vacante sin cubrir? El turno operará con déficit.' 
            : '¿Confirmas la asignación de ${substitute.fullName} como refuerzo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              context.read<ShiftsBloc>().add(PerformSubstitution(
                shiftId: shiftId,
                originalNeighborId: originalNeighbor.id,
                substituteNeighborId: substitute?.id,
                effectiveProfile: effectiveProfile,
              ));
              Navigator.pop(ctx); // Cierra diálogo
              Navigator.pop(context); // Cierra BottomSheet
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
