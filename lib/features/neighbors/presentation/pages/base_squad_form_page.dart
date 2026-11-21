import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_card.dart';
import 'package:rondon/core/widgets/app_text_field.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/presentation/cubit/base_squads_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/neighbors_cubit.dart';
import 'package:rondon/features/shifts/presentation/cubit/shift_templates_cubit.dart';
import 'package:uuid/uuid.dart';

class BaseSquadFormPage extends StatefulWidget {
  final BaseSquadEntity? squad;

  const BaseSquadFormPage({super.key, this.squad});

  @override
  State<BaseSquadFormPage> createState() => _BaseSquadFormPageState();
}

class _BaseSquadFormPageState extends State<BaseSquadFormPage> {
  // 1. Keys, Controllers & Local State
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<String> _selectedNeighborIds;
  String? _selectedTemplateId;

  bool get _isEditing => widget.squad != null;

  // 2. Lifecycle Methods
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.squad?.name);
    _selectedNeighborIds = widget.squad?.members.map((m) => m.id).toList() ?? [];
    _selectedTemplateId = widget.squad?.shiftTemplateId;

    context.read<NeighborsCubit>().loadNeighbors();
    context.read<ShiftTemplatesCubit>().loadShiftTemplates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 3. Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cuadrilla' : 'Nueva Cuadrilla'),
      ),
      body: MultiBlocBuilder(
        child: (neighborsState, templatesState) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                AppTextField(
                  label: 'Nombre de la Cuadrilla',
                  controller: _nameController,
                  prefixIcon: Icons.groups_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSizes.md),
                if (templatesState is ShiftTemplatesLoaded)
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedTemplateId,
                    decoration: const InputDecoration(
                      labelText: 'Vincular a Plantilla (Opcional)',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Rotación General')),
                      ...templatesState.templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedTemplateId = v),
                  ),
                const SizedBox(height: AppSizes.lg),
                Text('SELECCIONAR INTEGRANTES', style: context.design.labelCaps),
                const SizedBox(height: AppSizes.md),
                if (neighborsState.neighbors.isEmpty)
                  const Center(child: Text('No hay vecinos registrados para añadir.'))
                else
                  ...neighborsState.neighbors.map((neighbor) {
                    final isSelected = _selectedNeighborIds.contains(neighbor.id);
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: AppSizes.sm),
                      padding: EdgeInsets.zero,
                      child: CheckboxListTile(
                        title: Text(neighbor.fullName, style: context.textTheme.bodyLarge),
                        subtitle: Text(neighbor.operationalProfile.value, style: context.textTheme.bodySmall),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedNeighborIds.add(neighbor.id);
                            } else {
                              _selectedNeighborIds.remove(neighbor.id);
                            }
                          });
                        },
                        secondary: CircleAvatar(
                          radius: 16,
                          backgroundColor: neighbor.operationalProfile == OperationalProfile.active
                              ? context.colorScheme.primaryContainer
                              : context.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            neighbor.gender == Gender.male ? Icons.male : Icons.female,
                            size: 14,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: AppSizes.xl),
                AppButton.primary(
                  label: _isEditing ? 'GUARDAR CAMBIOS' : 'CREAR CUADRILLA',
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 4. Action Handlers & Async Callbacks
  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final neighborsState = context.read<NeighborsCubit>().state;
      final List<NeighborEntity> members = [];

      for (var id in _selectedNeighborIds) {
        final neighbor = neighborsState.neighbors.cast<NeighborEntity?>().firstWhere(
          (n) => n?.id == id,
          orElse: () => null,
        );
        if (neighbor != null) members.add(neighbor);
      }

      final squad = BaseSquadEntity(
        id: widget.squad?.id ?? const Uuid().v4(),
        name: _nameController.text,
        members: members,
        shiftTemplateId: _selectedTemplateId,
      );

      if (_isEditing) {
        context.read<BaseSquadsCubit>().editBaseSquad(squad);
      } else {
        context.read<BaseSquadsCubit>().addBaseSquad(squad);
      }
      Navigator.pop(context);
    }
  }

  // 5. Helper UI Builders / Sub-widgets
}

class MultiBlocBuilder extends StatelessWidget {
  final Widget Function(NeighborsState, ShiftTemplatesState) child;

  const MultiBlocBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NeighborsCubit, NeighborsState>(
      builder: (context, neighborsState) {
        return BlocBuilder<ShiftTemplatesCubit, ShiftTemplatesState>(
          builder: (context, templatesState) {
            return child(neighborsState, templatesState);
          },
        );
      },
    );
  }
}
