import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_text_field.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/presentation/cubit/shift_templates_cubit.dart';
import 'package:uuid/uuid.dart';

class ShiftTemplateFormPage extends StatefulWidget {
  final ShiftTemplateEntity? template;

  const ShiftTemplateFormPage({super.key, this.template});

  @override
  State<ShiftTemplateFormPage> createState() => _ShiftTemplateFormPageState();
}

class _ShiftTemplateFormPageState extends State<ShiftTemplateFormPage> {
  // 1. Keys, Controllers & Local State
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _quotaController;
  late TextEditingController _minActiveController;
  late AllowedGenderPolicy _selectedPolicy;
  late bool _isActive;

  bool get _isEditing => widget.template != null;

  // 2. Lifecycle Methods
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name);
    _startController = TextEditingController(text: widget.template?.startTime ?? '22:00');
    _endController = TextEditingController(text: widget.template?.endTime ?? '02:00');
    _quotaController = TextEditingController(text: widget.template?.targetQuota.toString() ?? '3');
    _minActiveController = TextEditingController(text: widget.template?.minActiveProfiles.toString() ?? '1');
    _selectedPolicy = widget.template?.allowedGender ?? AllowedGenderPolicy.mixed;
    _isActive = widget.template?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _quotaController.dispose();
    _minActiveController.dispose();
    super.dispose();
  }

  // 3. Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Plantilla' : 'Nueva Plantilla'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            AppTextField(
              label: 'Nombre de la Ronda',
              controller: _nameController,
              prefixIcon: Icons.alarm,
              hint: 'Ej: Ronda Nocturna',
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Inicio (HH:mm)',
                    controller: _startController,
                    prefixIcon: Icons.login,
                    hint: '22:00',
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: AppTextField(
                    label: 'Fin (HH:mm)',
                    controller: _endController,
                    prefixIcon: Icons.logout,
                    hint: '02:00',
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Cupo Total',
                    controller: _quotaController,
                    prefixIcon: Icons.groups_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null ? 'Número' : null,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: AppTextField(
                    label: 'Mín. Activos',
                    controller: _minActiveController,
                    prefixIcon: Icons.shield_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null ? 'Número' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Text('RESTRICCIÓN DE GÉNERO', style: context.design.labelCaps),
            const SizedBox(height: AppSizes.xs),
            DropdownButtonFormField<AllowedGenderPolicy>(
              initialValue: _selectedPolicy,
              items: AllowedGenderPolicy.values.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.value));
              }).toList(),
              onChanged: (v) => setState(() => _selectedPolicy = v!),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            ),
            const SizedBox(height: AppSizes.md),
            SwitchListTile(
              title: Text('Plantilla Activa', style: context.textTheme.bodyLarge),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSizes.xl),
            AppButton.primary(
              label: _isEditing ? 'GUARDAR CAMBIOS' : 'CREAR PLANTILLA',
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  // 4. Action Handlers & Async Callbacks
  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final template = ShiftTemplateEntity(
        id: widget.template?.id ?? const Uuid().v4(),
        name: _nameController.text,
        startTime: _startController.text,
        endTime: _endController.text,
        allowedGender: _selectedPolicy,
        targetQuota: int.tryParse(_quotaController.text) ?? 3,
        minActiveProfiles: int.tryParse(_minActiveController.text) ?? 1,
        displayOrder: widget.template?.displayOrder ?? 0,
        isActive: _isActive,
      );

      final cubit = context.read<ShiftTemplatesCubit>();
      if (_isEditing) {
        cubit.editShiftTemplate(template);
      } else {
        cubit.addShiftTemplate(template);
      }
      Navigator.pop(context);
    }
  }

  // 5. Helper UI Builders / Sub-widgets
}
