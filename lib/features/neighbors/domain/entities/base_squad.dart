import 'package:equatable/equatable.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';

class BaseSquadEntity extends Equatable {
  final String id;
  final String name;
  final String? shiftTemplateId;
  final List<NeighborEntity> members;

  const BaseSquadEntity({
    required this.id,
    required this.name,
    this.shiftTemplateId,
    this.members = const [],
  });

  @override
  List<Object?> get props => [id, name, shiftTemplateId, members];
}
