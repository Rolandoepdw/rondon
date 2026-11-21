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

  factory ShiftAssignmentEntity.fromMap(Map<String, dynamic> map, {NeighborEntity? neighbor}) {
    return ShiftAssignmentEntity(
      id: map['id'] as String,
      scheduledShiftId: map['scheduled_shift_id'] as String,
      neighborId: map['neighbor_id'] as String,
      neighbor: neighbor,
      isSubstitute: (map['is_substitute'] as int) == 1,
      substituteForNeighborId: map['substitute_for_neighbor_id'] as String?,
      attendanceStatus: AttendanceStatus.fromString(map['attendance_status'] as String),
      effectiveOperationalProfile: OperationalProfile.fromString(map['effective_operational_profile'] as String),
      balanceImpacted: (map['balance_impacted'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduled_shift_id': scheduledShiftId,
      'neighbor_id': neighborId,
      'is_substitute': isSubstitute ? 1 : 0,
      'substitute_for_neighbor_id': substituteForNeighborId,
      'attendance_status': attendanceStatus.value,
      'effective_operational_profile': effectiveOperationalProfile.value,
      'balance_impacted': balanceImpacted ? 1 : 0,
    };
  }

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
      .where((a) => a.effectiveOperationalProfile == OperationalProfile.active)
      .length;

  bool get meetsSecurityRequirements =>
      template == null || activeProfilesCount >= template!.minActiveProfiles;

  bool get isUnderQuota =>
      template != null && assignments.length < template!.targetQuota;

  factory ScheduledShiftEntity.fromMap(Map<String, dynamic> map, {
    ShiftTemplateEntity? template,
    List<ShiftAssignmentEntity> assignments = const [],
  }) {
    return ScheduledShiftEntity(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      shiftTemplateId: map['shift_template_id'] as String,
      template: template,
      status: ShiftStatus.fromString(map['status'] as String),
      notes: map['notes'] as String?,
      assignments: assignments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'shift_template_id': shiftTemplateId,
      'status': status.value,
      'notes': notes,
    };
  }

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
