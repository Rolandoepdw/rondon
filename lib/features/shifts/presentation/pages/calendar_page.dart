import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/theme/app_colors.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_badge.dart';
import 'package:rondon/core/widgets/app_empty_state.dart';
import 'package:rondon/core/widgets/app_shift_card.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/presentation/cubit/shifts_cubit.dart';
import 'package:rondon/features/shifts/presentation/pages/audit_shift_page.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // 1. Keys, Controllers & Local State
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 2. Lifecycle Methods
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadShiftsForMonth(_focusedDay);
  }

  // 3. Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: AppSizes.xl, height: AppSizes.xl),
            const SizedBox(width: AppSizes.sm),
            const Text('Calendario'),
          ],
        ),
      ),
      body: BlocBuilder<ShiftsCubit, ShiftsState>(
        builder: (context, state) {
          List<ScheduledShiftEntity> shifts = [];
          if (state is ShiftsLoaded) {
            shifts = state.todayShifts;
          }

          return Column(
            children: [
              TableCalendar<ScheduledShiftEntity>(
                locale: 'es_ES',
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(day, shifts),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadShiftsForMonth(focusedDay);
                },
                calendarStyle: CalendarStyle(
                  markersAlignment: Alignment.bottomCenter,
                  markerDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryContainer),
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: context.textTheme.bodyMedium!,
                  weekendTextStyle: context.textTheme.bodyMedium!.copyWith(color: AppColors.error),
                  outsideTextStyle: context.textTheme.bodySmall!.copyWith(color: AppColors.onSurfaceMuted),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: context.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: context.design.labelCaps,
                  weekendStyle: context.design.labelCaps.copyWith(color: AppColors.error),
                ),
              ),
              const Divider(height: 1, color: AppColors.outlineVariant),
              Expanded(
                child: _buildEventList(_getEventsForDay(_selectedDay!, shifts)),
              ),
            ],
          );
        },
      ),
    );
  }

  // 4. Action Handlers & Async Callbacks
  void _loadShiftsForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    context.read<ShiftsCubit>().loadShiftsRange(firstDay, lastDay);
  }

  List<ScheduledShiftEntity> _getEventsForDay(DateTime day, List<ScheduledShiftEntity> allShifts) {
    return allShifts.where((shift) => isSameDay(shift.date, day)).toList();
  }

  // 5. Helper UI Builders / Sub-widgets
  Widget _buildEventList(List<ScheduledShiftEntity> dayShifts) {
    if (dayShifts.isEmpty) {
      return const AppEmptyState(
        icon: Icons.event_available_outlined,
        title: 'Día libre',
        description: 'No hay guardias programadas para esta fecha.',
      );
    }

    return ListView.builder(
      itemCount: dayShifts.length,
      padding: const EdgeInsets.all(AppSizes.md),
      itemBuilder: (context, index) {
        final shift = dayShifts[index];
        return AppShiftCard(
          title: shift.template?.name ?? 'Turno',
          timeRange: '${shift.template?.startTime} - ${shift.template?.endTime}',
          details: [
            '${shift.assignments.length} vecinos asignados',
          ],
          badges: [
            AppBadge(
              label: shift.status.value,
              type: shift.status == ShiftStatus.auditado ? AppBadgeType.success : AppBadgeType.info,
            ),
          ],
          onMenuPressed: () {
            if (shift.status != ShiftStatus.auditado) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AuditShiftPage(shift: shift)),
              );
            }
          },
        );
      },
    );
  }
}
