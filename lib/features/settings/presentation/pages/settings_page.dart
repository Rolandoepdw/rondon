import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/utils/database_seeder.dart';
import 'package:rondon/features/neighbors/presentation/bloc/neighbors_bloc.dart';
import 'package:rondon/features/neighbors/presentation/bloc/base_squads_bloc.dart';
import 'package:rondon/features/shifts/presentation/bloc/shift_templates_bloc.dart';
import 'package:rondon/features/shifts/presentation/bloc/shifts_bloc.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';
import 'package:rondon/injection_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsRepo = sl<ISettingsRepository>();
  
  int _minDays = 3;
  bool _allowUnderQuota = true;
  String _morningTime = '08:00';
  String _eveningTime = '20:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final days = await _settingsRepo.getMinDaysBetweenShifts();
    final underQuota = await _settingsRepo.getAllowUnderQuota();
    final morning = await _settingsRepo.getMorningNotificationTime();
    final evening = await _settingsRepo.getEveningNotificationTime();
    
    if (mounted) {
      setState(() {
        _minDays = days.getOrElse(() => 3);
        _allowUnderQuota = underQuota.getOrElse(() => true);
        _morningTime = morning.getOrElse(() => '08:00');
        _eveningTime = evening.getOrElse(() => '20:00');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Reglas de Negocio'),
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: const Text('Días mínimos de descanso'),
            subtitle: Text('$_minDays días entre guardias'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showMinDaysDialog(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.person_off_outlined),
            title: const Text('Permitir déficit de personal'),
            subtitle: const Text('Cerrar turnos con menos vecinos del cupo'),
            value: _allowUnderQuota,
            onChanged: (val) async {
              await _settingsRepo.setAllowUnderQuota(val);
              setState(() => _allowUnderQuota = val);
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Notificaciones'),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Recordatorio Matutino'),
            subtitle: Text('Envío a las $_morningTime'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showTimeDialog(context, true),
          ),
          ListTile(
            leading: const Icon(Icons.nightlight_outlined),
            title: const Text('Recordatorio Vespertino'),
            subtitle: Text('Envío a las $_eveningTime'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showTimeDialog(context, false),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Desarrollo y Pruebas'),
          ListTile(
            leading: const Icon(Icons.data_usage, color: Colors.blue),
            title: const Text('Poblar Base de Datos (60 vecinos)'),
            subtitle: const Text('Borra todo y genera datos de prueba masivos'),
            onTap: () => _confirmAction(context, 'Poblar DB', '¿Seguro? Se crearán 60 vecinos, 10 cuadrillas y 3 plantillas.', () async {
              await DatabaseSeeder.seedDatabase();
              if (mounted) _refreshAllBlocs(context);
            }),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('Vaciar Base de Datos'),
            subtitle: const Text('Elimina absolutamente todos los datos'),
            onTap: () => _confirmAction(context, 'Vaciar DB', '¿Estás completamente seguro? Esta acción es irreversible.', () async {
              await DatabaseSeeder.clearDatabase();
              if (mounted) _refreshAllBlocs(context);
            }),
          ),
        ],
      ),
    );
  }

  void _refreshAllBlocs(BuildContext context) {
    context.read<NeighborsBloc>().add(LoadNeighbors());
    context.read<BaseSquadsBloc>().add(LoadBaseSquads());
    context.read<ShiftTemplatesBloc>().add(LoadShiftTemplates());
    context.read<ShiftsBloc>().add(LoadTodayShifts());
  }

  void _showMinDaysDialog(BuildContext context) {
    final controller = TextEditingController(text: _minDays.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Días de Descanso'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Mínimo de días entre turnos'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final val = int.tryParse(controller.text) ?? 3;
              await _settingsRepo.setMinDaysBetweenShifts(val);
              setState(() => _minDays = val);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showTimeDialog(BuildContext context, bool isMorning) {
    final initialTime = isMorning ? _morningTime : _eveningTime;
    final parts = initialTime.split(':');
    TimeOfDay time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    showTimePicker(
      context: context,
      initialTime: time,
    ).then((picked) async {
      if (picked != null) {
        final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isMorning) {
          await _settingsRepo.setMorningNotificationTime(newTime);
          setState(() => _morningTime = newTime);
        } else {
          await _settingsRepo.setEveningNotificationTime(newTime);
          setState(() => _eveningTime = newTime);
        }
      }
    });
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  void _confirmAction(BuildContext context, String title, String message, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await action();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Acción: $title completada')),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
