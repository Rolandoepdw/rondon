import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/presentation/bloc/neighbors_bloc.dart';
import 'package:rondon/features/neighbors/presentation/bloc/base_squads_bloc.dart';
import 'package:uuid/uuid.dart';

class NeighborDetailPage extends StatefulWidget {
  final String neighborId;

  const NeighborDetailPage({super.key, required this.neighborId});

  @override
  State<NeighborDetailPage> createState() => _NeighborDetailPageState();
}

class _NeighborDetailPageState extends State<NeighborDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<BaseSquadsBloc>().add(LoadBaseSquads());
    context.read<NeighborsBloc>().add(LoadLedgerHistory(widget.neighborId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NeighborsBloc, NeighborsState>(
      listenWhen: (prev, curr) => prev.neighbors != curr.neighbors,
      listener: (context, state) {
        final stillExists = state.neighbors.any((n) => n.id == widget.neighborId);
        if (!stillExists && state.neighbors.isNotEmpty) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final neighbor = state.neighbors.cast<NeighborEntity?>().firstWhere(
              (n) => n?.id == widget.neighborId,
              orElse: () => null,
            );

        if (neighbor == null) {
          return const Scaffold(
            body: Center(child: Text('Vecino no encontrado')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalles del Vecino'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showNeighborForm(context, neighbor: neighbor),
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, neighbor),
                tooltip: 'Eliminar',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<NeighborsBloc>().add(LoadNeighbors());
              context.read<NeighborsBloc>().add(LoadLedgerHistory(widget.neighborId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: neighbor.operationalProfile == OperationalProfile.activo 
                        ? Colors.green.shade100 
                        : Colors.orange.shade100,
                    child: Icon(
                      neighbor.gender == Gender.masculino ? Icons.male : Icons.female,
                      size: 50,
                      color: neighbor.operationalProfile == OperationalProfile.activo 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoSection(context, neighbor),
                const SizedBox(height: 24),
                _buildLedgerSection(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, NeighborEntity neighbor) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Nombre Completo'),
            subtitle: Text(neighbor.fullName),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Teléfono'),
            subtitle: Text(neighbor.phone ?? 'Sin teléfono'),
          ),
          const Divider(height: 1),
          BlocBuilder<BaseSquadsBloc, BaseSquadsState>(
            builder: (context, state) {
              String squadName = 'Ninguna';
              if (state is BaseSquadsLoaded && neighbor.baseSquadId != null) {
                final squad = state.squads.cast<BaseSquadEntity?>().firstWhere(
                  (s) => s?.id == neighbor.baseSquadId,
                  orElse: () => null,
                );
                if (squad != null) squadName = squad.name;
              }
              return ListTile(
                leading: const Icon(Icons.groups),
                title: const Text('Cuadrilla Base'),
                subtitle: Text(squadName),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Perfil Operativo'),
            subtitle: Text(neighbor.operationalProfile.value),
            trailing: Chip(
              label: Text(
                neighbor.isActive ? 'ACTIVO' : 'INACTIVO',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: neighbor.isActive ? Colors.green : Colors.grey,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Balance de Guardias'),
            subtitle: Text(neighbor.balance >= 0 
                ? 'Crédito / Al día' 
                : 'Deuda pendiente'),
            trailing: _buildBalanceChip(neighbor.balance),
          ),
          if (neighbor.notes != null && neighbor.notes!.isNotEmpty) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.notes),
              title: const Text('Notas'),
              subtitle: Text(neighbor.notes!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLedgerSection(BuildContext context, NeighborsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'HISTORIAL DE PUNTOS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (state.isLoading && state.ledgerHistory.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ))
        else if (state.ledgerHistory.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Sin movimientos registrados.', style: TextStyle(fontSize: 12, color: Colors.grey))),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.ledgerHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = state.ledgerHistory[index];
                final isPositive = record.delta > 0;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  title: Text(record.reason.value),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('d MMM, yyyy HH:mm').format(record.createdAt)),
                      if (record.notes != null && record.notes!.isNotEmpty)
                        Text(record.notes!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11)),
                    ],
                  ),
                  trailing: Text(
                    '${isPositive ? '+' : ''}${record.delta}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceChip(int balance) {
    Color color = Colors.grey;
    if (balance > 0) color = Colors.green;
    if (balance < 0) color = Colors.red;

    return Chip(
      label: Text(
        balance.toString(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
    );
  }

  void _showDeleteConfirmation(BuildContext context, NeighborEntity neighbor) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar a ${neighbor.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<NeighborsBloc>().add(RemoveNeighbor(neighbor.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNeighborForm(BuildContext context, {required NeighborEntity neighbor}) {
    final neighborsBloc = context.read<NeighborsBloc>();
    final squadsState = context.read<BaseSquadsBloc>().state;
    
    final nameController = TextEditingController(text: neighbor.fullName);
    final phoneController = TextEditingController(text: neighbor.phone);
    final notesController = TextEditingController(text: neighbor.notes);
    Gender selectedGender = neighbor.gender;
    OperationalProfile selectedProfile = neighbor.operationalProfile;
    bool isActive = neighbor.isActive;
    String? selectedSquadId = neighbor.baseSquadId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Vecino'),
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
                if (squadsState is BaseSquadsLoaded)
                  DropdownButtonFormField<String?>(
                    value: selectedSquadId,
                    decoration: const InputDecoration(labelText: 'Cuadrilla Base'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Ninguna')),
                      ...squadsState.squads.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => selectedSquadId = v),
                  ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notas / Observaciones'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Activo'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
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
                  final updatedNeighbor = NeighborEntity(
                    id: neighbor.id,
                    fullName: nameController.text,
                    phone: phoneController.text,
                    gender: selectedGender,
                    operationalProfile: selectedProfile,
                    balance: neighbor.balance,
                    isActive: isActive,
                    notes: notesController.text,
                    baseSquadId: selectedSquadId,
                  );
                  neighborsBloc.add(EditNeighbor(updatedNeighbor));
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
