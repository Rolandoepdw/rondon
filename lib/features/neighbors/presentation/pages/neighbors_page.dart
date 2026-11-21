import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_card.dart';
import 'package:rondon/core/widgets/app_empty_state.dart';
import 'package:rondon/core/widgets/app_neighbor_tile.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/presentation/cubit/base_squads_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/neighbors_cubit.dart';
import 'package:rondon/features/neighbors/presentation/pages/base_squad_form_page.dart';
import 'package:rondon/features/neighbors/presentation/pages/neighbor_detail_page.dart';
import 'package:rondon/features/neighbors/presentation/pages/neighbor_form_page.dart';
import 'package:rondon/features/settings/presentation/pages/shift_templates_page.dart';
import 'package:rondon/features/shifts/presentation/cubit/shift_templates_cubit.dart';

class NeighborsPage extends StatefulWidget {
  const NeighborsPage({super.key});

  @override
  State<NeighborsPage> createState() => _NeighborsPageState();
}

class _NeighborsPageState extends State<NeighborsPage> {
  // 1. Keys, Controllers & Local State

  // 2. Lifecycle Methods
  @override
  void initState() {
    super.initState();
    context.read<NeighborsCubit>().loadNeighbors();
    context.read<BaseSquadsCubit>().loadBaseSquads();
    context.read<ShiftTemplatesCubit>().loadShiftTemplates();
  }

  // 3. Build Method
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/images/logo.png', width: AppSizes.xl, height: AppSizes.xl),
              const SizedBox(width: AppSizes.sm),
              const Text('Gestión'),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vecinos'),
              Tab(text: 'Cuadrillas'),
              Tab(text: 'Plantillas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _NeighborsListTab(),
            _BaseSquadsListTab(),
            ShiftTemplatesPage(),
          ],
        ),
      ),
    );
  }

  // 4. Action Handlers & Async Callbacks

  // 5. Helper UI Builders / Sub-widgets
}

class _NeighborsListTab extends StatelessWidget {
  const _NeighborsListTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NeighborsCubit, NeighborsState>(
      builder: (context, state) {
        if (state.isLoading && state.neighbors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final isEmpty = state.neighbors.isEmpty;

        return Scaffold(
          body: isEmpty
              ? AppEmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'No hay vecinos',
                  description: 'Comienza agregando a los miembros de tu comunidad.',
                  action: AppButton.primary(
                    label: 'AGREGAR VECINO',
                    icon: Icons.person_add,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NeighborFormPage()),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: state.neighbors.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, index) {
                    final neighbor = state.neighbors[index];
                    return AppNeighborTile(
                      neighbor: neighbor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NeighborDetailPage(neighborId: neighbor.id),
                          ),
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NeighborFormPage()),
                  ),
                  child: const Icon(Icons.person_add),
                ),
        );
      },
    );
  }
}

class _BaseSquadsListTab extends StatelessWidget {
  const _BaseSquadsListTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BaseSquadsCubit, BaseSquadsState>(
      builder: (context, state) {
        if (state is BaseSquadsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BaseSquadsLoaded) {
          final isEmpty = state.squads.isEmpty;

          return Scaffold(
            body: isEmpty
                ? AppEmptyState(
                    icon: Icons.groups_2_outlined,
                    title: 'No hay cuadrillas',
                    description: 'Organiza a tus vecinos en grupos para facilitar la rotación.',
                    action: AppButton.primary(
                      label: 'CREAR CUADRILLA',
                      icon: Icons.group_add,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BaseSquadFormPage()),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.md),
                    itemCount: state.squads.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, index) {
                      final squad = state.squads[index];
                      return AppCard(
                        padding: EdgeInsets.zero,
                        child: ExpansionTile(
                          shape: const RoundedRectangleBorder(side: BorderSide.none),
                          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                          title: Text(squad.name, style: context.textTheme.titleMedium),
                          subtitle: Text('${squad.members.length} integrantes', style: context.design.labelCaps),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => BaseSquadFormPage(squad: squad)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                onPressed: () => _showDeleteConfirmation(context, squad),
                              ),
                            ],
                          ),
                          children: squad.members.map((m) => ListTile(
                            dense: true,
                            leading: Icon(Icons.person_outline, size: 16, color: context.colorScheme.primary),
                            title: Text(m.fullName, style: context.textTheme.bodyLarge),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NeighborDetailPage(neighborId: m.id),
                                ),
                              );
                            },
                          )).toList(),
                        ),
                      );
                    },
                  ),
            floatingActionButton: isEmpty
                ? null
                : FloatingActionButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BaseSquadFormPage()),
                    ),
                    child: const Icon(Icons.group_add),
                  ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, BaseSquadEntity squad) {
    context.showThemedDialog(
      title: const Text('Eliminar Cuadrilla'),
      content: Text('¿Estás seguro de que deseas eliminar la cuadrilla "${squad.name}"?'),
      actions: [
        AppButton.tertiary(
          label: 'CANCELAR',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'ELIMINAR',
          onPressed: () {
            context.read<BaseSquadsCubit>().removeBaseSquad(squad.id);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
