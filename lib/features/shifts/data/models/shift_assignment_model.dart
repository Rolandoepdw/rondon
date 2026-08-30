import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';

class ShiftAssignmentModel extends ShiftAssignmentEntity {
  const ShiftAssignmentModel({
    required super.id,
    required super.scheduledShiftId,
    required super.neighborId,
    super.neighbor,
    required super.isSubstitute,
    super.substituteForNeighborId,
    required super.attendanceStatus,
    required super.effectiveOperationalProfile,
    required super.balanceImpacted,
  });

  factory ShiftAssignmentModel.fromMap(Map<String, dynamic> map, {NeighborEntity? neighbor}) {
    return ShiftAssignmentModel(
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
}
