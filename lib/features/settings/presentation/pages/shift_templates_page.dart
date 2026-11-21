import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_badge.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_empty_state.dart';
import 'package:rondon/core/widgets/app_shift_card.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/presentation/cubit/shift_templates_cubit.dart';
import 'package:rondon/features/shifts/presentation/pages/shift_template_form_page.dart';

class ShiftTemplatesPage extends StatefulWidget {
  const ShiftTemplatesPage({super.key});

  @override
  State<ShiftTemplatesPage> createState() => _ShiftTemplatesPageState();
}

class _ShiftTemplatesPageState extends State<ShiftTemplatesPage> {
  // 1. Keys, Controllers & Local State

  // 2. Lifecycle Methods
  @override
  void initState() {
    super.initState();
    context.read<ShiftTemplatesCubit>().loadShiftTemplates();
  }

  // 3. Build Method
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftTemplatesCubit, ShiftTemplatesState>(
      builder: (context, state) {
        if (state is ShiftTemplatesLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ShiftTemplatesLoaded) {
          final isEmpty = state.templates.isEmpty;
          return Scaffold(
            body: isEmpty
                ? AppEmptyState(
                    icon: Icons.alarm_off_outlined,
                    title: 'Sin plantillas',
                    description: 'Define los horarios de las guardias para automatizar la planificación.',
                    action: AppButton.primary(
                      label: 'CREAR PLANTILLA',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShiftTemplateFormPage()),
                      ),
                    ),
                  )
                : _buildList(context, state.templates),
            floatingActionButton: isEmpty
                ? null
                : FloatingActionButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShiftTemplateFormPage()),
                    ),
                    child: const Icon(Icons.add_alarm),
                  ),
          );
        } else if (state is ShiftTemplatesError) {
          return Scaffold(
            body: Center(child: Text('Error: ${state.message}')),
          );
        }
        return const Scaffold(
          body: Center(child: Text('Cargando plantillas...')),
        );
      },
    );
  }

  // 4. Action Handlers & Async Callbacks
  void _showDeleteConfirmation(BuildContext context, ShiftTemplateEntity template) {
    context.showThemedDialog(
      title: const Text('Eliminar Plantilla'),
      content: Text('¿Deseas eliminar la plantilla "${template.name}"? Esta acción no afectará las guardias ya generadas.'),
      actions: [
        AppButton.tertiary(
          label: 'CANCELAR',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'ELIMINAR',
          onPressed: () {
            context.read<ShiftTemplatesCubit>().removeShiftTemplate(template.id);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // 5. Helper UI Builders / Sub-widgets
  Widget _buildList(BuildContext context, List<ShiftTemplateEntity> templates) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return AppShiftCard(
          title: template.name,
          timeRange: '${template.startTime} - ${template.endTime}',
          details: [
            'Cupo objetivo: ${template.targetQuota} personas',
            'Mínimo de activos: ${template.minActiveProfiles}',
          ],
          badges: [
            AppBadge(
              label: template.allowedGender.value,
              type: AppBadgeType.info,
            ),
            if (!template.isActive)
              const AppBadge(label: 'INACTIVA', type: AppBadgeType.error)
            else
              const AppBadge(label: 'ACTIVA', type: AppBadgeType.success),
          ],
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ShiftTemplateFormPage(template: template)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(context, template),
              ),
            ],
          ),
        );
      },
    );
  }
}
