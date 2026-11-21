import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rondon/core/theme/app_sizes.dart';
import 'package:rondon/core/theme/theme_context_ext.dart';
import 'package:rondon/core/widgets/app_badge.dart';
import 'package:rondon/core/widgets/app_button.dart';
import 'package:rondon/core/widgets/app_card.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/presentation/cubit/base_squads_cubit.dart';
import 'package:rondon/features/neighbors/presentation/cubit/neighbors_cubit.dart';
import 'package:rondon/features/neighbors/presentation/pages/neighbor_form_page.dart';

class NeighborDetailPage extends StatefulWidget {
  final String neighborId;

  const NeighborDetailPage({super.key, required this.neighborId});

  @override
  State<NeighborDetailPage> createState() => _NeighborDetailPageState();
}

class _NeighborDetailPageState extends State<NeighborDetailPage> {
  // 1. Keys, Controllers & Local State

  // 2. Lifecycle Methods
  @override
  void initState() {
    super.initState();
    context.read<BaseSquadsCubit>().loadBaseSquads();
    context.read<NeighborsCubit>().loadLedgerHistory(widget.neighborId);
  }

  // 3. Build Method
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NeighborsCubit, NeighborsState>(
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
            title: const Text('Ficha del Vecino'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NeighborFormPage(neighbor: neighbor)),
                ),
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(context, neighbor),
                tooltip: 'Eliminar',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<NeighborsCubit>().loadNeighbors();
              context.read<NeighborsCubit>().loadLedgerHistory(widget.neighborId);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                _buildProfileHeader(context, neighbor),
                const SizedBox(height: AppSizes.lg),
                _buildInfoSection(context, neighbor),
                const SizedBox(height: AppSizes.xl),
                _buildLedgerSection(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  // 4. Action Handlers & Async Callbacks
  void _showDeleteConfirmation(BuildContext context, NeighborEntity neighbor) {
    context.showThemedDialog(
      title: const Text('Confirmar eliminación'),
      content: Text('¿Estás seguro de que deseas eliminar a ${neighbor.fullName}? Esta acción no se puede deshacer.'),
      actions: [
        AppButton.tertiary(
          label: 'CANCELAR',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'ELIMINAR',
          onPressed: () {
            context.read<NeighborsCubit>().removeNeighbor(neighbor.id);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // 5. Helper UI Builders / Sub-widgets
  Widget _buildProfileHeader(BuildContext context, NeighborEntity neighbor) {
    final bool isActivo = neighbor.operationalProfile == OperationalProfile.active;

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: isActivo ? context.colorScheme.primaryContainer : context.colorScheme.surfaceContainerHighest,
              child: Icon(
                isActivo ? Icons.shield : Icons.person,
                size: 48,
                color: isActivo ? context.colorScheme.onPrimaryContainer : context.colorScheme.onSurfaceVariant,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colorScheme.outlineVariant, width: 2),
                ),
                child: Icon(
                  neighbor.gender == Gender.male ? Icons.male : Icons.female,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Text(neighbor.fullName, style: context.textTheme.headlineLarge),
        const SizedBox(height: AppSizes.xs),
        Text(neighbor.phone ?? 'Sin teléfono', style: context.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, NeighborEntity neighbor) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildInfoRow(context, Icons.groups_outlined, 'Cuadrilla Base', _getSquadName(neighbor)),
          const Divider(height: 1),
          _buildInfoRow(
            context,
            Icons.admin_panel_settings_outlined,
            'Perfil Operativo',
            neighbor.operationalProfile.value,
            trailing: AppBadge(
              label: neighbor.isActive ? 'ACTIVO' : 'INACTIVO',
              type: neighbor.isActive ? AppBadgeType.success : AppBadgeType.info,
            ),
          ),
          const Divider(height: 1),
          _buildInfoRow(
            context,
            Icons.account_balance_wallet_outlined,
            'Balance Actual',
            '${neighbor.balance} guardias',
            trailing: Text(
              neighbor.balance.toString(),
              style: context.design.scoreNum.copyWith(
                color: neighbor.balance < 0 ? context.colorScheme.error : context.colorScheme.primary,
                fontSize: 24,
              ),
            ),
          ),
          if (neighbor.notes != null && neighbor.notes!.isNotEmpty) ...[
            const Divider(height: 1),
            _buildInfoRow(context, Icons.notes, 'Observaciones', neighbor.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: context.colorScheme.primary, size: 20),
      title: Text(label, style: context.design.labelCaps),
      subtitle: Text(value, style: context.textTheme.bodyLarge),
      trailing: trailing,
    );
  }

  String _getSquadName(NeighborEntity neighbor) {
    final state = context.read<BaseSquadsCubit>().state;
    if (state is BaseSquadsLoaded && neighbor.baseSquadId != null) {
      final squad = state.squads.cast<BaseSquadEntity?>().firstWhere(
        (s) => s?.id == neighbor.baseSquadId,
        orElse: () => null,
      );
      if (squad != null) return squad.name;
    }
    return 'Ninguna';
  }

  Widget _buildLedgerSection(BuildContext context, NeighborsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HISTORIAL DE PUNTOS', style: context.design.labelCaps),
        const SizedBox(height: AppSizes.md),
        if (state.isLoading && state.ledgerHistory.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (state.ledgerHistory.isEmpty)
          const AppCard(
            child: Center(
              child: Text('Sin movimientos registrados.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          )
        else
          ...state.ledgerHistory.map((record) {
            final isPositive = record.delta > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  ),
                  title: Text(record.reason.value, style: context.textTheme.bodyLarge),
                  subtitle: Text(DateFormat('d MMM, yyyy HH:mm').format(record.createdAt), style: context.textTheme.bodySmall),
                  trailing: Text(
                    '${isPositive ? '+' : ''}${record.delta}',
                    style: context.design.scoreNum.copyWith(
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
