import 'package:equatable/equatable.dart';

enum AllowedGenderPolicy {
  femaleOnly('FEMALE_ONLY'),
  maleOnly('MALE_ONLY'),
  mixed('MIXED');

  final String value;
  const AllowedGenderPolicy(this.value);

  static AllowedGenderPolicy fromString(String val) =>
      AllowedGenderPolicy.values.firstWhere((e) => e.value == val, orElse: () => AllowedGenderPolicy.mixed);

  String get displayName {
    switch (this) {
      case AllowedGenderPolicy.femaleOnly:
        return 'Solo Mujeres';
      case AllowedGenderPolicy.maleOnly:
        return 'Solo Hombres';
      case AllowedGenderPolicy.mixed:
        return 'Mixto';
    }
  }
}

class ShiftTemplateEntity extends Equatable {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final AllowedGenderPolicy allowedGender;
  final int targetQuota;
  final int minActiveProfiles;
  final int displayOrder;
  final bool isActive;

  const ShiftTemplateEntity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.allowedGender,
    required this.targetQuota,
    required this.minActiveProfiles,
    required this.displayOrder,
    required this.isActive,
  });

  factory ShiftTemplateEntity.fromMap(Map<String, dynamic> map) {
    return ShiftTemplateEntity(
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

  @override
  List<Object?> get props => [
        id,
        name,
        startTime,
        endTime,
        allowedGender,
        targetQuota,
        minActiveProfiles,
        displayOrder,
        isActive,
      ];
}
