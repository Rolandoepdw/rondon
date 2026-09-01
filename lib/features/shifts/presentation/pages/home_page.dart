import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';
import 'package:rondon/core/services/whatsapp_service.dart';
import 'package:rondon/features/messaging/domain/usecases/build_reminder_message.dart';
import 'package:rondon/injection_container.dart';
import 'package:rondon/features/shifts/presentation/pages/audit_shift_page.dart';
import 'package:rondon/features/shifts/presentation/widgets/replacement_bottom_sheet.dart';
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
        if (state.pendingAuditShifts.isNotEmpty)
          _buildPendingAuditBanner(context, state.pendingAuditShifts),
        
        // Sección de Hoy
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📅 HOY: $dateStr',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (state.todayShifts.isEmpty)
              TextButton.icon(
                onPressed: () => _showGenerateDialog(context),
                icon: const Icon(Icons.add_chart),
                label: const Text('Planificar'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.todayShifts.isEmpty)
          _buildEmptyState(context)
        else
          ...state.todayShifts.map((shift) => _ShiftCard(shift: shift)),

        // Sección de Turnos de Ayer (si están visibles o se desea mostrar historial rápido)
        if (state.pendingAuditShifts.isNotEmpty) ...[
          const Divider(height: 32),
          Text(
            '⏳ GUARDIAS PASADAS PENDIENTES',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...state.pendingAuditShifts.map((shift) => _ShiftCard(shift: shift)),
        ],
      ],
    );
  }

  Widget _buildPendingAuditBanner(BuildContext context, List<ScheduledShiftEntity> pending) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: const Text('Auditoría Pendiente', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Hay ${pending.length} guardias de anoche sin cerrar.'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AuditShiftPage(shift: pending.first)),
          );
        },
      ),
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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  if (picked != null) setDialogState(() => startDate = picked);
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
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                bloc.add(GenerateShiftsRange(startDate: startDate, endDate: endDate));
                Navigator.pop(context);
              },
              child: const Text('Generar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final ScheduledShiftEntity shift;

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
                    a.effectiveOperationalProfile == OperationalProfile.activo ? Icons.bolt : Icons.accessibility_new,
                    size: 14,
                    color: a.effectiveOperationalProfile == OperationalProfile.activo ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('${a.neighbor?.fullName ?? 'Desconocido'} (${a.isSubstitute ? 'Refuerzo' : 'Titular'})'),
                  ),
                  if (shift.status != ShiftStatus.auditado)
                    IconButton(
                      icon: const Icon(Icons.person_remove_outlined, size: 16, color: Colors.orange),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => BlocProvider.value(
                            value: context.read<ShiftsBloc>(),
                            child: ReplacementBottomSheet(
                              shiftId: shift.id,
                              originalNeighbor: a.neighbor!,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Reemplazar',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showWhatsAppMenu(context),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 8),
                if (shift.status != ShiftStatus.auditado)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AuditShiftPage(shift: shift)),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Auditar'),
                    ),
                  ),
                if (shift.status == ShiftStatus.auditado)
                  const Expanded(
                    child: Center(child: Text('✅ Auditado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ShiftStatus status) {
    return Chip(
      label: Text(status.value, style: const TextStyle(fontSize: 10)),
      backgroundColor: Colors.blue.shade50,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showWhatsAppMenu(BuildContext context) {
    final builder = sl<BuildReminderMessage>();
    final service = sl<WhatsAppService>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.group, color: Colors.green),
            title: const Text('Enviar resumen al grupo'),
            onTap: () {
              Navigator.pop(ctx);
              final msg = builder.buildBroadcast(shift);
              service.sendBroadcastMessage(msg);
            },
          ),
          const Divider(),
          ...shift.assignments.map((a) => ListTile(
            leading: const Icon(Icons.person),
            title: Text('Notificar a ${a.neighbor?.fullName}'),
            subtitle: Text(a.neighbor?.phone ?? 'Sin teléfono'),
            enabled: a.neighbor?.phone != null,
            onTap: () {
              Navigator.pop(ctx);
              final msg = builder(shift, a);
              service.sendIndividualMessage(a.neighbor!.phone!, msg);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
