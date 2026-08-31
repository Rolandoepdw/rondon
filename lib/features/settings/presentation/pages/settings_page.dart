import 'package:flutter/material.dart';
import 'package:rondon/features/settings/presentation/pages/shift_templates_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'General'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Parámetros de Descanso'),
            subtitle: const Text('Días mínimos entre guardias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implementar diálogo de parámetros globales
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Planificación'),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Plantillas de Turno'),
            subtitle: const Text('Configura los horarios y cupos de guardias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShiftTemplatesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Cuadrillas Base'),
            subtitle: const Text('Grupos de afinidad habituales'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navegar a cuadrillas
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Notificaciones'),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Recordatorios WhatsApp'),
            subtitle: const Text('Horarios de aviso automático'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Configurar horas de notificación
            },
          ),
        ],
      ),
    );
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
}
