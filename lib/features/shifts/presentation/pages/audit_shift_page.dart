import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rondon/core/theme/app_colors.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_card.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/presentation/cubit/shifts_cubit.dart';

class AuditShiftPage extends StatefulWidget {
  final ScheduledShiftEntity shift;

  const AuditShiftPage({super.key, required this.shift});

  @override
  State<AuditShiftPage> createState() => _AuditShiftPageState();
}

class _AuditShiftPageState extends State<AuditShiftPage> {
  // 1. Keys, Controllers & Local State
  late Map<String, AttendanceStatus> _attendanceMap;
  final _notesController = TextEditingController();

  // 2. Lifecycle Methods
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

  // 3. Build Method
  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM', 'es_ES').format(widget.shift.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditar Asistencia'),
      ),
      body: Column(
        children: [
          _buildHeader(context, dateStr),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              children: [
                ...widget.shift.assignments.map((assignment) {
                  final neighbor = assignment.neighbor;
                  final status = _attendanceMap[neighbor?.id] ?? AttendanceStatus.presente;
                  final impact = _calculateImpact(assignment, status);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                    child: AppCard(
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: context.colorScheme.surfaceContainerHighest,
                              child: Text(neighbor?.fullName[0] ?? '?', style: TextStyle(color: context.colorScheme.onSurfaceVariant)),
                            ),
                            title: Text(neighbor?.fullName ?? 'Desconocido', style: context.textTheme.titleMedium),
                            subtitle: Text(
                              '${assignment.isSubstitute ? 'Refuerzo' : 'Titular'} • Bal: ${neighbor?.balance ?? 0}',
                              style: context.textTheme.bodySmall,
                            ),
                            trailing: _buildImpactBadge(context, impact, neighbor?.balance ?? 0),
                          ),
                          const SizedBox(height: AppSizes.md),
                          Row(
                            children: [
                              _AttendanceButton(
                                label: 'PRESENTE',
                                isSelected: status == AttendanceStatus.presente,
                                activeColor: Colors.greenAccent,
                                onTap: () => setState(() => _attendanceMap[neighbor!.id] = AttendanceStatus.presente),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              _AttendanceButton(
                                label: 'FALTA',
                                isSelected: status == AttendanceStatus.falta,
                                activeColor: Colors.redAccent,
                                onTap: () => setState(() => _attendanceMap[neighbor!.id] = AttendanceStatus.falta),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: AppCard(
                    child: TextField(
                      controller: _notesController,
                      style: context.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'NOTAS DE LA AUDITORÍA',
                        labelStyle: context.design.labelCaps,
                        hintText: 'Ej: Noche tranquila, reporte de novedades...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                      maxLines: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  // 4. Action Handlers & Async Callbacks
  int _calculateImpact(ShiftAssignmentEntity assignment, AttendanceStatus status) {
    if (status == AttendanceStatus.presente) {
      if (assignment.isSubstitute) return 1;
      return 0;
    } else {
      if (assignment.balanceImpacted) return 0;
      return -1;
    }
  }

  void _confirmAudit(BuildContext context) {
    context.showThemedDialog(
      title: const Text('Confirmar Auditoría'),
      content: const Text('Al confirmar, se actualizarán los balances de todos los vecinos participantes. Esta acción es definitiva.'),
      actions: [
        AppButton.tertiary(
          label: 'CANCELAR',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'CONFIRMAR',
          onPressed: () {
            context.read<ShiftsCubit>().auditShift(
              shiftId: widget.shift.id,
              attendanceMap: _attendanceMap,
              notes: _notesController.text,
            );
            Navigator.pop(context); // Cierra diálogo
            Navigator.pop(this.context); // Regresa al Dashboard
          },
        ),
      ],
    );
  }

  // 5. Helper UI Builders / Sub-widgets
  Widget _buildHeader(BuildContext context, String dateStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(bottom: BorderSide(color: context.colorScheme.outlineVariant.withAlpha(76))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.shift.template?.name ?? 'Turno',
            style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_month, size: 14, color: context.colorScheme.primary),
              const SizedBox(width: 4),
              Text(dateStr.toUpperCase(), style: context.design.labelCaps),
              const SizedBox(width: AppSizes.md),
              Icon(Icons.schedule, size: 14, color: context.colorScheme.primary),
              const SizedBox(width: 4),
              Text('${widget.shift.template?.startTime} - ${widget.shift.template?.endTime}', style: context.design.labelCaps),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(top: BorderSide(color: context.colorScheme.outlineVariant.withAlpha(76))),
      ),
      child: AppButton.primary(
        label: 'GUARDAR Y CERRAR AUDITORÍA',
        onPressed: () => _confirmAudit(context),
      ),
    );
  }

  Widget _buildImpactBadge(BuildContext context, int impact, int currentBalance) {
    if (impact == 0) return const SizedBox.shrink();

    final color = impact > 0 ? Colors.greenAccent : Colors.redAccent;
    final text = impact > 0 ? '+1' : '-1';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(color: color.withAlpha(127)),
          ),
          child: Text(
            text,
            style: context.design.scoreNum.copyWith(color: color, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _AttendanceButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? activeColor.withAlpha(25) : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          side: BorderSide(
            color: isSelected ? activeColor : context.colorScheme.outlineVariant.withAlpha(76),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.design.labelCaps.copyWith(
                color: isSelected ? activeColor : AppColors.onSurfaceMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
