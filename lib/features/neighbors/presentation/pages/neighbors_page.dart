import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/features/neighbors/presentation/bloc/neighbors_bloc.dart';
import 'package:rondon/features/neighbors/presentation/bloc/base_squads_bloc.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/presentation/pages/neighbor_detail_page.dart';
import 'package:uuid/uuid.dart';

class NeighborsPage extends StatelessWidget {
  const NeighborsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comunidad'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Vecinos'),
              Tab(icon: Icon(Icons.groups), text: 'Cuadrillas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _NeighborsListTab(),
            _BaseSquadsListTab(),
          ],
        ),
      ),
    );
  }
}

class _NeighborsListTab extends StatelessWidget {
  const _NeighborsListTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NeighborsBloc, NeighborsState>(
      builder: (context, state) {
        if (state is NeighborsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is NeighborsLoaded) {
          return _buildList(context, state.neighbors);
        } else if (state is NeighborsError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('Cargando vecinos...'));
      },
    );
  }

  Widget _buildList(BuildContext context, List<NeighborEntity> neighbors) {
    if (neighbors.isEmpty) {
      return const Center(
        child: Text('Aún no hay vecinos registrados.'),
      );
    }

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: neighbors.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final neighbor = neighbors[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: neighbor.operationalProfile == OperationalProfile.activo 
                  ? Colors.green.shade100 
                  : Colors.orange.shade100,
              child: Icon(
                neighbor.gender == Gender.masculino ? Icons.male : Icons.female,
                color: neighbor.operationalProfile == OperationalProfile.activo 
                    ? Colors.green 
                    : Colors.orange,
              ),
            ),
            title: Text(neighbor.fullName),
            subtitle: Text(neighbor.phone ?? 'Sin teléfono'),
            trailing: _buildBalanceChip(neighbor.balance),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNeighborForm(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBalanceChip(int balance) {
    Color color = Colors.grey;
    if (balance > 0) color = Colors.green;
    if (balance < 0) color = Colors.red;

    return Chip(
      label: Text(
        balance.toString(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showNeighborForm(BuildContext context) {
    final neighborsBloc = context.read<NeighborsBloc>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    Gender selectedGender = Gender.masculino;
    OperationalProfile selectedProfile = OperationalProfile.activo;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Vecino'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre Completo'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const Text('Género:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Radio<Gender>(
                      value: Gender.masculino,
                      groupValue: selectedGender,
                      onChanged: (v) => setState(() => selectedGender = v!),
                    ),
                    const Text('M'),
                    Radio<Gender>(
                      value: Gender.femenino,
                      groupValue: selectedGender,
                      onChanged: (v) => setState(() => selectedGender = v!),
                    ),
                    const Text('F'),
                  ],
                ),
                const Text('Perfil Operativo:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<OperationalProfile>(
                  value: selectedProfile,
                  isExpanded: true,
                  items: OperationalProfile.values.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.value));
                  }).toList(),
                  onChanged: (v) => setState(() => selectedProfile = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newNeighbor = NeighborEntity(
                    id: const Uuid().v4(),
                    fullName: nameController.text,
                    phone: phoneController.text,
                    gender: selectedGender,
                    operationalProfile: selectedProfile,
                    balance: 0,
                    isActive: true,
                  );
                  neighborsBloc.add(AddNeighbor(newNeighbor));
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

class _BaseSquadsListTab extends StatelessWidget {
  const _BaseSquadsListTab();

  @override
  Widget build(BuildContext context) {
    context.read<BaseSquadsBloc>().add(LoadBaseSquads());
    
    return BlocBuilder<BaseSquadsBloc, BaseSquadsState>(
      builder: (context, state) {
        if (state is BaseSquadsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BaseSquadsLoaded) {
          return _buildSquadsList(context, state.squads);
        } else if (state is BaseSquadsError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('Cargando cuadrillas...'));
      },
    );
  }

  Widget _buildSquadsList(BuildContext context, List<BaseSquadEntity> squads) {
    return Scaffold(
      body: squads.isEmpty
          ? const Center(child: Text('No hay cuadrillas configuradas.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: squads.length,
              itemBuilder: (context, index) {
                final squad = squads[index];
                return Card(
                  child: ExpansionTile(
                    title: Text(squad.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${squad.members.length} integrantes'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'delete') {
                          context.read<BaseSquadsBloc>().add(RemoveBaseSquad(squad.id));
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                    children: squad.members.map((m) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline, size: 16),
                      title: Text(m.fullName),
                    )).toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSquadForm(context),
        child: const Icon(Icons.group_add),
      ),
    );
  }

  void _showSquadForm(BuildContext context) {
    final bloc = context.read<BaseSquadsBloc>();
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva Cuadrilla'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre de la Cuadrilla'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                bloc.add(AddBaseSquad(BaseSquadEntity(
                  id: const Uuid().v4(),
                  name: nameController.text,
                )));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
