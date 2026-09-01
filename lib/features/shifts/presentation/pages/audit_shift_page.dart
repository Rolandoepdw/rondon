import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';
import 'package:intl/intl.dart';

class AuditShiftPage extends StatefulWidget {
  final ScheduledShiftEntity shift;

  const AuditShiftPage({super.key, required this.shift});

  @override
  State<AuditShiftPage> createState() => _AuditShiftPageState();
}

class _AuditShiftPageState extends State<AuditShiftPage> {
  late Map<String, AttendanceStatus> _attendanceMap;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _attendanceMap = {
      for (var a in widget.shift.assignments) 
        a.neighborId: a.attendanceStatus == AttendanceStatus.pendiente 
            ? AttendanceStatus.presente 
            : a.attendanceStatus
    };
    _notesController.text = widget.shift.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM', 'es_ES').format(widget.shift.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditar Asistencia'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shift.template?.name ?? 'Turno',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text('📅 $dateStr'),
                Text('⏰ ${widget.shift.template?.startTime} - ${widget.shift.template?.endTime}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Marque la asistencia real de los participantes para impactar los balances de guardias.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ...widget.shift.assignments.map((assignment) {
                  final neighbor = assignment.neighbor;
                  final status = _attendanceMap[neighbor?.id] ?? AttendanceStatus.presente;
                  final impact = _calculateImpact(assignment, status);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              child: Text(neighbor?.fullName[0] ?? '?'),
                            ),
                            title: Text(neighbor?.fullName ?? 'Desconocido'),
                            subtitle: Text('${assignment.isSubstitute ? 'Refuerzo' : 'Titular'} • Bal: ${neighbor?.balance ?? 0}'),
                            trailing: _buildImpactBadge(impact, neighbor?.balance ?? 0),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ChoiceChip(
                                label: const Text('PRESENTE'),
                                selected: status == AttendanceStatus.presente,
                                selectedColor: Colors.green.shade100,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _attendanceMap[neighbor!.id] = AttendanceStatus.presente;
                                    });
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text('FALTA'),
                                selected: status == AttendanceStatus.falta,
                                selectedColor: Colors.red.shade100,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _attendanceMap[neighbor!.id] = AttendanceStatus.falta;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas de la Auditoría',
                      hintText: 'Ej: Turno tranquilo, María llegó 10 min tarde...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _confirmAudit(context),
                icon: const Icon(Icons.save),
                label: const Text('CERRAR Y GUARDAR AUDITORÍA'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAudit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Auditoría'),
        content: const Text('Al confirmar, se actualizarán los balances de todos los vecinos participantes. Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              context.read<ShiftsBloc>().add(AuditShift(
                shiftId: widget.shift.id,
                attendanceMap: _attendanceMap,
                notes: _notesController.text,
              ));
              Navigator.pop(ctx); // Cierra diálogo
              Navigator.pop(context); // Regresa al Dashboard
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  int _calculateImpact(ShiftAssignmentEntity assignment, AttendanceStatus status) {
    if (status == AttendanceStatus.presente) {
      if (assignment.isSubstitute) return 1;
      return 0;
    } else {
      // Si ya fue penalizado (balanceImpacted == true), no volvemos a penalizar
      if (assignment.balanceImpacted) return 0;
      return -1;
    }
  }

  Widget _buildImpactBadge(int impact, int currentBalance) {
    if (impact == 0) return const SizedBox.shrink();
    
    final color = impact > 0 ? Colors.green : Colors.red;
    final text = impact > 0 ? '+1' : '-1';
    final nextBalance = currentBalance + impact;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Próx: $nextBalance',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
