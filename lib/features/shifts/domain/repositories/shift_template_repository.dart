import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';

abstract class IShiftTemplateRepository {
  Future<Either<Failure, List<ShiftTemplateEntity>>> getActiveTemplates();
  Future<Either<Failure, void>> createTemplate(ShiftTemplateEntity template);
  Future<Either<Failure, void>> updateTemplate(ShiftTemplateEntity template);
  Future<Either<Failure, void>> deleteTemplate(String id);
}
