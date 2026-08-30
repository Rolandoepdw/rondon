import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';

class ScheduledShiftModel extends ScheduledShiftEntity {
  const ScheduledShiftModel({
    required super.id,
    required super.date,
    required super.shiftTemplateId,
    super.template,
    required super.status,
    super.notes,
    super.assignments = const [],
  });

  factory ScheduledShiftModel.fromMap(Map<String, dynamic> map, {
    ShiftTemplateEntity? template,
    List<ShiftAssignmentEntity> assignments = const [],
  }) {
    return ScheduledShiftModel(
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
      'date': date.toIso8601String().split('T')[0], // Solo YYYY-MM-DD
      'shift_template_id': shiftTemplateId,
      'status': status.value,
      'notes': notes,
    };
  }
}
