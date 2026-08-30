import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';

class NeighborModel extends NeighborEntity {
  const NeighborModel({
    required super.id,
    required super.fullName,
    super.phone,
    required super.gender,
    required super.operationalProfile,
    super.baseSquadId,
    required super.balance,
    required super.isActive,
    super.notes,
  });

  factory NeighborModel.fromMap(Map<String, dynamic> map) {
    return NeighborModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      gender: Gender.fromString(map['gender'] as String),
      operationalProfile: OperationalProfile.fromString(map['operational_profile'] as String),
      baseSquadId: map['base_squad_id'] as String?,
      balance: map['balance'] as int,
      isActive: (map['is_active'] as int) == 1,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'gender': gender.value,
      'operational_profile': operationalProfile.value,
      'base_squad_id': baseSquadId,
      'balance': balance,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  factory NeighborModel.fromEntity(NeighborEntity entity) {
    return NeighborModel(
      id: entity.id,
      fullName: entity.fullName,
      phone: entity.phone,
      gender: entity.gender,
      operationalProfile: entity.operationalProfile,
      baseSquadId: entity.baseSquadId,
      balance: entity.balance,
      isActive: entity.isActive,
      notes: entity.notes,
    );
  }

  NeighborEntity toEntity() => this;
}
