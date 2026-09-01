import 'package:equatable/equatable.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

class BalanceLedgerRecordEntity extends Equatable {
  final String id;
  final String neighborId;
  final String? scheduledShiftId;
  final int delta;
  final LedgerReason reason;
  final String? notes;
  final DateTime createdAt;

  const BalanceLedgerRecordEntity({
    required this.id,
    required this.neighborId,
    this.scheduledShiftId,
    required this.delta,
    required this.reason,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, neighborId, scheduledShiftId, delta, reason, notes, createdAt];
}
