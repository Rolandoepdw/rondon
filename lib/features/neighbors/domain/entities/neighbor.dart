import 'package:equatable/equatable.dart';

enum Gender {
  male('MALE'),
  female('FEMALE');

  final String value;
  const Gender(this.value);

  static Gender fromString(String val) =>
      Gender.values.firstWhere((e) => e.value == val, orElse: () => Gender.male);

  String get displayName => this == Gender.male ? 'Masculino' : 'Femenino';
}

enum OperationalProfile {
  active('ACTIVE'),
  support('SUPPORT');

  final String value;
  const OperationalProfile(this.value);

  static OperationalProfile fromString(String val) =>
      OperationalProfile.values.firstWhere((e) => e.value == val, orElse: () => OperationalProfile.active);

  String get displayName => this == OperationalProfile.active ? 'Activo' : 'Apoyo';
}

class NeighborEntity extends Equatable {
  final String id;
  final String fullName;
  final String? phone;
  final Gender gender;
  final OperationalProfile operationalProfile;
  final String? baseSquadId;
  final int balance;
  final bool isActive;
  final String? notes;

  const NeighborEntity({
    required this.id,
    required this.fullName,
    this.phone,
    required this.gender,
    required this.operationalProfile,
    this.baseSquadId,
    required this.balance,
    required this.isActive,
    this.notes,
  });

  bool get owesShifts => balance < 0;
  bool get hasCredits => balance > 0;

  factory NeighborEntity.fromMap(Map<String, dynamic> map) {
    return NeighborEntity(
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

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        gender,
        operationalProfile,
        baseSquadId,
        balance,
        isActive,
        notes,
      ];
}
