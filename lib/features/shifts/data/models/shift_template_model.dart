import 'package:rondon/features/shifts/domain/entities/shift_template.dart';

class ShiftTemplateModel extends ShiftTemplateEntity {
  const ShiftTemplateModel({
    required super.id,
    required super.name,
    required super.startTime,
    required super.endTime,
    required super.allowedGender,
    required super.targetQuota,
    required super.minActiveProfiles,
    required super.displayOrder,
    required super.isActive,
  });

  factory ShiftTemplateModel.fromMap(Map<String, dynamic> map) {
    return ShiftTemplateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      allowedGender: AllowedGenderPolicy.fromString(map['allowed_gender'] as String),
      targetQuota: map['target_quota'] as int,
      minActiveProfiles: map['min_active_profiles'] as int,
      displayOrder: map['display_order'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'allowed_gender': allowedGender.value,
      'target_quota': targetQuota,
      'min_active_profiles': minActiveProfiles,
      'display_order': displayOrder,
      'is_active': isActive ? 1 : 0,
    };
  }
}
