import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/theme/app_colors.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/utils/database_seeder.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_text_field.dart';
import 'package:rondon/features/neighbors/presentation/cubit/base_squads_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/neighbors_cubit.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';
import 'package:rondon/features/shifts/presentation/cubit/shift_templates_cubit.dart';
import 'package:rondon/features/shifts/presentation/cubit/shifts_cubit.dart';
import 'package:rondon/injection_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 1. Keys, Controllers & Local State
  final _settingsRepo = sl<ISettingsRepository>();

  int _minDays = 3;
  bool _allowUnderQuota = true;
  String _morningTime = '08:00';
  String _eveningTime = '20:00';

  // 2. Lifecycle Methods
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

    if (!mounted) return;
    setState(() {
      _minDays = days.getOrElse(() => 3);
      _allowUnderQuota = underQuota.getOrElse(() => true);
      _morningTime = morning.getOrElse(() => '08:00');
      _eveningTime = evening.getOrElse(() => '20:00');
    });
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
            const Text('Ajustes del Sistema'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        children: [
          _buildSectionHeader(context, 'Reglas de Negocio'),
          ListTile(
            leading: Icon(Icons.event_busy, color: context.colorScheme.primary),
            title: const Text('Días mínimos de descanso'),
            subtitle: Text('$_minDays días obligatorios entre guardias'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _showMinDaysDialog(context),
          ),
          SwitchListTile(
            secondary: Icon(Icons.person_off_outlined, color: context.colorScheme.primary),
            title: const Text('Permitir déficit de personal'),
            subtitle: const Text('Habilita el cierre de turnos sin completar el cupo objetivo'),
            value: _allowUnderQuota,
            onChanged: (val) async {
              await _settingsRepo.setAllowUnderQuota(val);
              if (!mounted) return;
              setState(() => _allowUnderQuota = val);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 32),
          ),
          _buildSectionHeader(context, 'Notificaciones WhatsApp'),
          ListTile(
            leading: Icon(Icons.wb_sunny_outlined, color: context.colorScheme.primary),
            title: const Text('Recordatorio Matutino'),
            subtitle: Text('Programado para las $_morningTime'),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _showTimeDialog(context, true),
          ),
          ListTile(
            leading: Icon(Icons.nightlight_outlined, color: context.colorScheme.primary),
            title: const Text('Recordatorio Vespertino'),
            subtitle: Text('Programado para las $_eveningTime'),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _showTimeDialog(context, false),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 32),
          ),
          _buildSectionHeader(context, 'Herramientas de Datos'),
          ListTile(
            leading: const Icon(Icons.data_usage, color: Colors.blueAccent),
            title: const Text('Poblar Base de Datos'),
            subtitle: const Text('Generar 60 vecinos y datos de prueba iniciales'),
            onTap: () => _confirmAction(context, 'Poblar DB', 'Se borrarán los datos actuales y se crearán 60 vecinos, 10 cuadrillas y 3 plantillas.', () async {
              await DatabaseSeeder.seedDatabase();
              _refreshAllBlocs();
            }),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            title: const Text('Limpiar Todo'),
            subtitle: const Text('Eliminar permanentemente todos los registros del sistema'),
            onTap: () => _confirmAction(context, 'Vaciar DB', '¿Estás completamente seguro? Esta acción eliminará vecinos, turnos e historial.', () async {
              await DatabaseSeeder.clearDatabase();
              _refreshAllBlocs();
            }),
          ),
          const SizedBox(height: AppSizes.xl),
          Center(
            child: Text(
              'RONDÓN v1.0.0',
              style: context.design.labelCaps.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Action Handlers & Async Callbacks
  void _refreshAllBlocs() {
    if (!mounted) return;
    context.read<NeighborsCubit>().loadNeighbors();
    context.read<BaseSquadsCubit>().loadBaseSquads();
    context.read<ShiftTemplatesCubit>().loadShiftTemplates();
    context.read<ShiftsCubit>().loadTodayShifts();
  }

  void _showMinDaysDialog(BuildContext dialogContext) {
    final controller = TextEditingController(text: _minDays.toString());
    dialogContext.showThemedDialog(
      title: const Text('Días de Descanso'),
      content: AppTextField(
        label: 'Mínimo de días',
        controller: controller,
        keyboardType: TextInputType.number,
        hint: 'Ej: 3',
      ),
      actions: [
        AppButton.tertiary(
          label: 'CANCELAR',
          onPressed: () => Navigator.pop(dialogContext),
        ),
        AppButton.primary(
          label: 'GUARDAR',
          onPressed: () async {
            final val = int.tryParse(controller.text) ?? 3;
            await _settingsRepo.setMinDaysBetweenShifts(val);
            if (!mounted) return;
            setState(() => _minDays = val);
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
          },
        ),
      ],
    );
  }

  void _showTimeDialog(BuildContext dialogContext, bool isMorning) {
    final initialTime = isMorning ? _morningTime : _eveningTime;
    final parts = initialTime.split(':');
    final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    showTimePicker(
      context: dialogContext,
      initialTime: time,
      builder: (ctx, child) {
        return Theme(
          data: ctx.theme.copyWith(
            colorScheme: ctx.colorScheme.copyWith(
              surface: AppColors.surfaceContainerHigh,
            ),
          ),
          child: child!,
        );
      },
    ).then((picked) async {
      if (picked != null) {
        final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isMorning) {
          await _settingsRepo.setMorningNotificationTime(newTime);
          if (!mounted) return;
          setState(() => _morningTime = newTime);
        } else {
          await _settingsRepo.setEveningNotificationTime(newTime);
          if (!mounted) return;
          setState(() => _eveningTime = newTime);
        }
      }
    });
  }

  void _confirmAction(BuildContext dialogContext, String title, String message, Future<void> Function() action) {
    final messenger = ScaffoldMessenger.of(dialogContext);
    dialogContext.showThemedDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton.tertiary(
          label: 'CANCELAR',
          onPressed: () => Navigator.pop(dialogContext),
        ),
        AppButton.primary(
          label: 'CONFIRMAR',
          onPressed: () async {
            Navigator.pop(dialogContext);
            await action();
            messenger.showSnackBar(
              SnackBar(content: Text('Operación exitosa: $title')),
            );
          },
        ),
      ],
    );
  }

  // 5. Helper UI Builders / Sub-widgets
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: context.design.labelCaps.copyWith(
          color: context.colorScheme.primary,
        ),
      ),
    );
  }
}
