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

  @override
  void initState() {
    super.initState();
    _attendanceMap = {
      for (var a in widget.shift.assignments) 
        a.neighborId: a.attendanceStatus == AttendanceStatus.pendiente 
            ? AttendanceStatus.presente 
            : a.attendanceStatus
    };
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
            child: ListView.builder(
              itemCount: widget.shift.assignments.length,
              itemBuilder: (context, index) {
                final assignment = widget.shift.assignments[index];
                final neighbor = assignment.neighbor;
                final status = _attendanceMap[neighbor?.id] ?? AttendanceStatus.presente;

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
                          subtitle: Text(assignment.isSubstitute ? 'Refuerzo' : 'Titular'),
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
              },
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
}
