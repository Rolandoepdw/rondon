import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/presentation/bloc/shift_templates_bloc.dart';
import 'package:uuid/uuid.dart';

class ShiftTemplatesPage extends StatelessWidget {
  const ShiftTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Aseguramos que se carguen las plantillas al entrar
    context.read<ShiftTemplatesBloc>().add(LoadShiftTemplates());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Turno'),
      ),
      body: BlocBuilder<ShiftTemplatesBloc, ShiftTemplatesState>(
        builder: (context, state) {
          if (state is ShiftTemplatesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ShiftTemplatesLoaded) {
            return _buildList(context, state.templates);
          } else if (state is ShiftTemplatesError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Cargando plantillas...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateForm(context),
        child: const Icon(Icons.add_alarm),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ShiftTemplateEntity> templates) {
    if (templates.isEmpty) {
      return const Center(
        child: Text('No hay plantillas configuradas.\nAgregue una para empezar la planificación.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          child: ListTile(
            title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('⏰ ${template.startTime} - ${template.endTime}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGenderIcon(template.allowedGender),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showTemplateForm(context, template: template);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, template);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderIcon(AllowedGenderPolicy policy) {
    IconData icon;
    Color color;
    switch (policy) {
      case AllowedGenderPolicy.soloMujeres:
        icon = Icons.female;
        color = Colors.pink;
        break;
      case AllowedGenderPolicy.soloHombres:
        icon = Icons.male;
        color = Colors.blue;
        break;
      case AllowedGenderPolicy.mixto:
        icon = Icons.wc;
        color = Colors.purple;
        break;
    }
    return Icon(icon, color: color, size: 20);
  }

  void _showDeleteConfirmation(BuildContext context, ShiftTemplateEntity template) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Plantilla'),
        content: Text('¿Deseas eliminar la plantilla "${template.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<ShiftTemplatesBloc>().add(RemoveShiftTemplate(template.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTemplateForm(BuildContext context, {ShiftTemplateEntity? template}) {
    final bloc = context.read<ShiftTemplatesBloc>();
    final nameController = TextEditingController(text: template?.name);
    final startController = TextEditingController(text: template?.startTime ?? '22:00');
    final endController = TextEditingController(text: template?.endTime ?? '02:00');
    final quotaController = TextEditingController(text: template?.targetQuota.toString() ?? '3');
    final minActiveController = TextEditingController(text: template?.minActiveProfiles.toString() ?? '1');
    AllowedGenderPolicy selectedPolicy = template?.allowedGender ?? AllowedGenderPolicy.mixto;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(template == null ? 'Nueva Plantilla' : 'Editar Plantilla'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre (ej: Turno Madrugada)')),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startController, decoration: const InputDecoration(labelText: 'Inicio (HH:mm)'))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: endController, decoration: const InputDecoration(labelText: 'Fin (HH:mm)'))),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: TextField(controller: quotaController, decoration: const InputDecoration(labelText: 'Cupo Total'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: minActiveController, decoration: const InputDecoration(labelText: 'Min. Activos'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Política de Género:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<AllowedGenderPolicy>(
                  value: selectedPolicy,
                  isExpanded: true,
                  items: AllowedGenderPolicy.values.map((p) => DropdownMenuItem(value: p, child: Text(p.value))).toList(),
                  onChanged: (v) => setState(() => selectedPolicy = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newTemplate = ShiftTemplateEntity(
                    id: template?.id ?? const Uuid().v4(),
                    name: nameController.text,
                    startTime: startController.text,
                    endTime: endController.text,
                    allowedGender: selectedPolicy,
                    targetQuota: int.tryParse(quotaController.text) ?? 3,
                    minActiveProfiles: int.tryParse(minActiveController.text) ?? 1,
                    displayOrder: template?.displayOrder ?? 0,
                    isActive: true,
                  );
                  if (template == null) bloc.add(AddShiftTemplate(newTemplate));
                  else bloc.add(EditShiftTemplate(newTemplate));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
