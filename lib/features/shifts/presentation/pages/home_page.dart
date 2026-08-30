import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ RONDON'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ShiftsBloc>().add(LoadTodayShifts());
            },
          ),
        ],
      ),
      body: BlocBuilder<ShiftsBloc, ShiftsState>(
        builder: (context, state) {
          if (state is ShiftsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ShiftsLoaded) {
            return _buildDashboard(context, state);
          } else if (state is ShiftsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Inicia el día planificando.'));
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ShiftsLoaded state) {
    final dateStr = DateFormat('EEEE, d de MMMM', 'es_ES').format(state.date);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '📅 HOY: $dateStr',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (state.shifts.isEmpty)
          _buildEmptyState(context)
        else
          ...state.shifts.map((shift) => _ShiftCard(shift: shift)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay guardias programadas para hoy.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Navegar a calendario
              },
              child: const Text('Generar Planificación'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final dynamic shift;

  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shift.template?.name ?? 'Turno',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusChip(shift.status),
              ],
            ),
            const Divider(),
            Text('⏰ ${shift.template?.startTime} - ${shift.template?.endTime}'),
            const SizedBox(height: 8),
            const Text('👥 Participantes:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Gestionar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(dynamic status) {
    return Chip(
      label: Text(status.value, style: const TextStyle(fontSize: 10)),
      backgroundColor: Colors.blue.shade50,
      visualDensity: VisualDensity.compact,
    );
  }
}
