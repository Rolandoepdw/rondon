import 'package:equatable/equatable.dart';

enum AllowedGenderPolicy {
  soloMujeres('SOLO_MUJERES'),
  soloHombres('SOLO_HOMBRES'),
  mixto('MIXTO');

  final String value;
  const AllowedGenderPolicy(this.value);

  static AllowedGenderPolicy fromString(String val) =>
      AllowedGenderPolicy.values.firstWhere((e) => e.value == val);
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
