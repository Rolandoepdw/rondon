import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/presentation/bloc/neighbors_bloc.dart';

class NeighborDetailPage extends StatelessWidget {
  final String neighborId;

  const NeighborDetailPage({super.key, required this.neighborId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NeighborsBloc, NeighborsState>(
      listener: (context, state) {
        if (state is NeighborsLoaded) {
          final stillExists = state.neighbors.any((n) => n.id == neighborId);
          if (!stillExists) {
            Navigator.pop(context);
          }
        }
      },
      child: BlocBuilder<NeighborsBloc, NeighborsState>(
        builder: (context, state) {
          if (state is NeighborsLoaded) {
            final neighbor = state.neighbors.cast<NeighborEntity?>().firstWhere(
                  (n) => n?.id == neighborId,
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
              body: ListView(
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
                ],
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
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
            trailing: neighbor.phone != null ? IconButton(
              icon: const Icon(Icons.message, color: Colors.green),
              onPressed: () {
                // TODO: Link a WhatsApp
              },
            ) : null,
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
    final nameController = TextEditingController(text: neighbor.fullName);
    final phoneController = TextEditingController(text: neighbor.phone);
    final notesController = TextEditingController(text: neighbor.notes);
    Gender selectedGender = neighbor.gender;
    OperationalProfile selectedProfile = neighbor.operationalProfile;
    bool isActive = neighbor.isActive;

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
