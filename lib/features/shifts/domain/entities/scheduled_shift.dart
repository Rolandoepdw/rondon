import 'package:equatable/equatable.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';

enum ShiftStatus {
  planificado('PLANIFICADO'),
  replanificado('REPLANIFICADO'),
  enCurso('EN_CURSO'),
  auditado('AUDITADO'),
  deficitOperativo('DEFICIT_OPERATIVO');

  final String value;
  const ShiftStatus(this.value);

  static ShiftStatus fromString(String val) =>
      ShiftStatus.values.firstWhere((e) => e.value == val);
}

enum AttendanceStatus {
  pendiente('PENDIENTE'),
  presente('PRESENTE'),
  falta('FALTA');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String val) =>
      AttendanceStatus.values.firstWhere((e) => e.value == val);
}

class ShiftAssignmentEntity extends Equatable {
  final String id;
  final String scheduledShiftId;
  final String neighborId;
  final NeighborEntity? neighbor;
  final bool isSubstitute;
  final String? substituteForNeighborId;
  final AttendanceStatus attendanceStatus;
  final OperationalProfile effectiveOperationalProfile;
  final bool balanceImpacted;

  const ShiftAssignmentEntity({
    required this.id,
    required this.scheduledShiftId,
    required this.neighborId,
    this.neighbor,
    required this.isSubstitute,
    this.substituteForNeighborId,
    required this.attendanceStatus,
    required this.effectiveOperationalProfile,
    required this.balanceImpacted,
  });

  @override
  List<Object?> get props => [
        id,
        scheduledShiftId,
        neighborId,
        neighbor,
        isSubstitute,
        substituteForNeighborId,
        attendanceStatus,
        effectiveOperationalProfile,
        balanceImpacted,
      ];
}

class ScheduledShiftEntity extends Equatable {
  final String id;
  final DateTime date;
  final String shiftTemplateId;
  final ShiftTemplateEntity? template;
  final ShiftStatus status;
  final String? notes;
  final List<ShiftAssignmentEntity> assignments;

  const ScheduledShiftEntity({
    required this.id,
    required this.date,
    required this.shiftTemplateId,
    this.template,
    required this.status,
    this.notes,
    this.assignments = const [],
  });

  int get currentCount => assignments.length;

  int get activeProfilesCount => assignments
      .where((a) => a.effectiveOperationalProfile == OperationalProfile.activo)
      .length;

  bool get meetsSecurityRequirements =>
      template == null || activeProfilesCount >= template!.minActiveProfiles;

  bool get isUnderQuota =>
      template != null && assignments.length < template!.targetQuota;

  @override
  List<Object?> get props => [
        id,
        date,
        shiftTemplateId,
        template,
        status,
        notes,
        assignments,
      ];
}
