import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShiftsBloc, ShiftsState>(
      listener: (context, state) {
        if (state is ShiftsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is ShiftsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<ShiftsBloc>().add(LoadTodayShifts()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Inicia el día planificando.'));
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ShiftsLoaded state) {
    final dateStr = DateFormat('EEEE, d de MMMM', 'es_ES').format(state.date);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📅 HOY: $dateStr',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (state.shifts.isEmpty)
              TextButton.icon(
                onPressed: () => _showGenerateDialog(context),
                icon: const Icon(Icons.add_chart),
                label: const Text('Planificar'),
              ),
          ],
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
              onPressed: () => _showGenerateDialog(context),
              child: const Text('Generar Planificación'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    final bloc = context.read<ShiftsBloc>();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generar Planificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Se generarán los turnos automáticamente basados en las plantillas y rotación de cuadrillas.'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Desde'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(startDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) startDate = picked;
              },
            ),
            ListTile(
              title: const Text('Hasta'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(endDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: endDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) endDate = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              bloc.add(GenerateShiftsRange(startDate: startDate, endDate: endDate));
              Navigator.pop(dialogContext);
            },
            child: const Text('Generar'),
          ),
        ],
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
            const SizedBox(height: 4),
            ...shift.assignments.map((a) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
              child: Row(
                children: [
                  Icon(
                    a.neighbor?.operationalProfile == OperationalProfile.activo ? Icons.bolt : Icons.accessibility_new,
                    size: 14,
                    color: a.neighbor?.operationalProfile == OperationalProfile.activo ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text('${a.neighbor?.fullName ?? 'Desconocido'} (${a.isSubstitute ? 'Refuerzo' : 'Titular'})'),
                ],
              ),
            )).toList(),
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
