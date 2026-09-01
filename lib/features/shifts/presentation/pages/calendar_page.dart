import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadShiftsForMonth(_focusedDay);
  }

  void _loadShiftsForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    context.read<ShiftsBloc>().add(LoadShiftsRange(start: firstDay, end: lastDay));
  }

  List<ScheduledShiftEntity> _getEventsForDay(DateTime day, List<ScheduledShiftEntity> allShifts) {
    return allShifts.where((shift) => isSameDay(shift.date, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Guardias'),
      ),
      body: BlocBuilder<ShiftsBloc, ShiftsState>(
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
                calendarStyle: const CalendarStyle(
                  markersAlignment: Alignment.bottomCenter,
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: _buildEventList(_getEventsForDay(_selectedDay!, shifts)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<ScheduledShiftEntity> dayShifts) {
    if (dayShifts.isEmpty) {
      return const Center(
        child: Text('No hay guardias para este día.'),
      );
    }

    return ListView.builder(
      itemCount: dayShifts.length,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) {
        final shift = dayShifts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.shield,
              color: shift.status == ShiftStatus.auditado ? Colors.green : Colors.blue,
            ),
            title: Text(shift.template?.name ?? 'Turno'),
            subtitle: Text('⏰ ${shift.template?.startTime} - ${shift.template?.endTime}'),
            trailing: Text(
              shift.status.value,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
