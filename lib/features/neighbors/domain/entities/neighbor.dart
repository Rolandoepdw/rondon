import 'package:equatable/equatable.dart';

enum Gender {
  masculino('MASCULINO'),
  femenino('FEMENINO');

  final String value;
  const Gender(this.value);

  static Gender fromString(String val) =>
      Gender.values.firstWhere((e) => e.value == val);
}

enum OperationalProfile {
  activo('ACTIVO'),
  apoyo('APOYO');

  final String value;
  const OperationalProfile(this.value);

  static OperationalProfile fromString(String val) =>
      OperationalProfile.values.firstWhere((e) => e.value == val);
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
