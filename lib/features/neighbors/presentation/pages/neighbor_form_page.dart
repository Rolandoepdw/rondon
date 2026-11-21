import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_text_field.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/presentation/cubit/base_squads_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/neighbors_cubit.dart';
import 'package:uuid/uuid.dart';

class NeighborFormPage extends StatefulWidget {
  final NeighborEntity? neighbor;

  const NeighborFormPage({super.key, this.neighbor});

  @override
  State<NeighborFormPage> createState() => _NeighborFormPageState();
}

class _NeighborFormPageState extends State<NeighborFormPage> {
  // 1. Keys, Controllers & Local State
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late Gender _selectedGender;
  late OperationalProfile _selectedProfile;
  late bool _isActive;
  String? _selectedSquadId;

  bool get _isEditing => widget.neighbor != null;

  // 2. Lifecycle Methods
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.neighbor?.fullName);
    _phoneController = TextEditingController(text: widget.neighbor?.phone);
    _notesController = TextEditingController(text: widget.neighbor?.notes);
    _selectedGender = widget.neighbor?.gender ?? Gender.male;
    _selectedProfile = widget.neighbor?.operationalProfile ?? OperationalProfile.active;
    _isActive = widget.neighbor?.isActive ?? true;
    _selectedSquadId = widget.neighbor?.baseSquadId;

    context.read<BaseSquadsCubit>().loadBaseSquads();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // 3. Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Vecino' : 'Nuevo Vecino'),
      ),
      body: BlocBuilder<BaseSquadsCubit, BaseSquadsState>(
        builder: (context, squadsState) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                AppTextField(
                  label: 'Nombre Completo',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSizes.md),
                AppTextField(
                  label: 'Teléfono',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSizes.md),
                if (squadsState is BaseSquadsLoaded)
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedSquadId,
                    decoration: const InputDecoration(
                      labelText: 'Cuadrilla Base',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Ninguna')),
                      ...squadsState.squads.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedSquadId = v),
                  ),
                const SizedBox(height: AppSizes.md),
                AppTextField(
                  label: 'Notas / Observaciones',
                  controller: _notesController,
                  maxLines: 3,
                  prefixIcon: Icons.notes,
                ),
                const SizedBox(height: AppSizes.lg),
                Text('GÉNERO', style: context.design.labelCaps),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    _GenderOption(
                      label: 'Masculino',
                      isSelected: _selectedGender == Gender.male,
                      onTap: () => setState(() => _selectedGender = Gender.male),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    _GenderOption(
                      label: 'Femenino',
                      isSelected: _selectedGender == Gender.female,
                      onTap: () => setState(() => _selectedGender = Gender.female),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                Text('PERFIL OPERATIVO', style: context.design.labelCaps),
                const SizedBox(height: AppSizes.xs),
                DropdownButtonFormField<OperationalProfile>(
                  initialValue: _selectedProfile,
                  items: OperationalProfile.values.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.value));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedProfile = v!),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                ),
                const SizedBox(height: AppSizes.md),
                SwitchListTile(
                  title: Text('Vecino Activo', style: context.textTheme.bodyLarge),
                  subtitle: Text('Los vecinos inactivos no son incluidos en la planificación automática.', style: context.textTheme.bodySmall),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSizes.xl),
                AppButton.primary(
                  label: _isEditing ? 'GUARDAR CAMBIOS' : 'CREAR VECINO',
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
      final neighbor = NeighborEntity(
        id: widget.neighbor?.id ?? const Uuid().v4(),
        fullName: _nameController.text,
        phone: _phoneController.text,
        gender: _selectedGender,
        operationalProfile: _selectedProfile,
        balance: widget.neighbor?.balance ?? 0,
        isActive: _isActive,
        notes: _notesController.text,
        baseSquadId: _selectedSquadId,
      );

      if (_isEditing) {
        context.read<NeighborsCubit>().editNeighbor(neighbor);
      } else {
        context.read<NeighborsCubit>().addNeighbor(neighbor);
      }
      Navigator.pop(context);
    }
  }

  // 5. Helper UI Builders / Sub-widgets
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? context.colorScheme.primaryContainer : context.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          side: BorderSide(
            color: isSelected ? context.colorScheme.primary : context.colorScheme.outlineVariant.withAlpha(127),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : context.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
