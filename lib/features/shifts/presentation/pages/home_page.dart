import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rondon/core/services/whatsapp_service.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_badge.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_empty_state.dart';
import 'package:rondon/core/widgets/app_shift_card.dart';
import 'package:rondon/features/messaging/domain/usecases/build_reminder_message.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/presentation/cubit/shifts_cubit.dart';
import 'package:rondon/features/shifts/presentation/pages/audit_shift_page.dart';
import 'package:rondon/injection_container.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShiftsCubit, ShiftsState>(
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', width: AppSizes.xl, height: AppSizes.xl),
              const SizedBox(width: AppSizes.sm),
              Text('RONDÓN', style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              )),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<ShiftsCubit>().loadTodayShifts();
              },
            ),
          ],
        ),
        body: BlocBuilder<ShiftsCubit, ShiftsState>(
          builder: (context, state) {
            if (state is ShiftsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ShiftsLoaded) {
              return _buildDashboard(context, state);
            } else if (state is ShiftsError) {
              return AppEmptyState(
                icon: Icons.error_outline,
                title: 'Error al cargar',
                description: state.message,
                action: AppButton.primary(
                  label: 'REINTENTAR',
                  onPressed: () => context.read<ShiftsCubit>().loadTodayShifts(),
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
    final dateStr = DateFormat('EEEE, d MMMM', 'es_ES').format(state.date);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.md),
      children: [
        if (state.pendingAuditShifts.isNotEmpty)
          _buildPendingAuditBanner(context, state.pendingAuditShifts),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HOY: ${dateStr.toUpperCase()}',
              style: context.design.labelCaps,
            ),
            if (state.todayShifts.isEmpty)
              AppButton.tertiary(
                label: 'PLANIFICAR',
                icon: Icons.add_chart,
                onPressed: () => _showGenerateDialog(context),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        if (state.todayShifts.isEmpty)
          AppEmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Sin guardias hoy',
            description: 'No hay actividad programada para esta fecha.',
            action: AppButton.primary(
              label: 'GENERAR PLANIFICACIÓN',
              onPressed: () => _showGenerateDialog(context),
            ),
          )
        else
          ...state.todayShifts.map((shift) => _ShiftCardRemodeled(shift: shift)),

        if (state.pendingAuditShifts.isNotEmpty) ...[
          const SizedBox(height: AppSizes.xl),
          Text(
            '⏳ GUARDIAS PASADAS PENDIENTES',
            style: context.design.labelCaps.copyWith(color: context.colorScheme.error),
          ),
          const SizedBox(height: AppSizes.md),
          ...state.pendingAuditShifts.map((shift) => _ShiftCardRemodeled(shift: shift)),
        ],
      ],
    );
  }

  Widget _buildPendingAuditBanner(BuildContext context, List<ScheduledShiftEntity> pending) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Material(
        color: context.colorScheme.errorContainer.withAlpha(51),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: context.colorScheme.error.withAlpha(76)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(Icons.warning_amber_rounded, color: context.colorScheme.error),
          title: Text('Auditoría Pendiente', style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text('Hay ${pending.length} guardias sin cerrar.', style: context.textTheme.bodySmall),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AuditShiftPage(shift: pending.first)),
            );
          },
        ),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    final cubit = context.read<ShiftsCubit>();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    context.showThemedDialog(
      title: const Text('Generar Planificación'),
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Se generarán los turnos automáticamente basados en las plantillas y rotación de cuadrillas.'),
            const SizedBox(height: AppSizes.md),
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
      ),
      actions: [
        AppButton.tertiary(
          label: 'CANCELAR',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'GENERAR',
          onPressed: () {
            cubit.generateShiftsRange(startDate, endDate);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _ShiftCardRemodeled extends StatelessWidget {
  final ScheduledShiftEntity shift;

  const _ShiftCardRemodeled({required this.shift});

  @override
  Widget build(BuildContext context) {
    return AppShiftCard(
      title: shift.template?.name ?? 'Turno',
      timeRange: '${shift.template?.startTime} - ${shift.template?.endTime}',
      details: shift.assignments.map((a) {
        final profile = a.effectiveOperationalProfile == OperationalProfile.active ? 'ACT' : 'APO';
        final type = a.isSubstitute ? 'REF' : 'TIT';
        return '${a.neighbor?.fullName} ($profile/$type)';
      }).toList(),
      badges: [
        AppBadge(
          label: shift.status.value,
          type: shift.status == ShiftStatus.auditado ? AppBadgeType.success : AppBadgeType.info,
        ),
      ],
      actions: [
        AppButton.secondary(
          label: 'WHATSAPP',
          icon: Icons.message_outlined,
          onPressed: () => _showWhatsAppMenu(context),
        ),
        if (shift.status != ShiftStatus.auditado)
          AppButton.primary(
            label: 'AUDITAR',
            icon: Icons.check_circle_outline,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AuditShiftPage(shift: shift)),
              );
            },
          ),
      ],
    );
  }

  void _showWhatsAppMenu(BuildContext context) {
    final builder = sl<BuildReminderMessage>();
    final service = sl<WhatsAppService>();

    context.showThemedBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSizes.md),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Text('NOTIFICACIONES WHATSAPP', style: context.design.labelCaps),
          ),
          ListTile(
            leading: const Icon(Icons.group, color: Colors.green),
            title: const Text('Enviar resumen al grupo'),
            onTap: () {
              Navigator.pop(context);
              final msg = builder.buildBroadcast(shift);
              service.sendBroadcastMessage(msg);
            },
          ),
          const Divider(),
          ...shift.assignments.map((a) => ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('Notificar a ${a.neighbor?.fullName}'),
            subtitle: Text(a.neighbor?.phone ?? 'Sin teléfono'),
            enabled: a.neighbor?.phone != null,
            onTap: () {
              Navigator.pop(context);
              final msg = builder(shift, a);
              service.sendIndividualMessage(a.neighbor!.phone!, msg);
            },
          )),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}
