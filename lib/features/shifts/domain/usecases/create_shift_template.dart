import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';

class CreateShiftTemplate implements UseCase<void, ShiftTemplateEntity> {
  final IShiftTemplateRepository repository;

  CreateShiftTemplate(this.repository);

  @override
  Future<Either<Failure, void>> call(ShiftTemplateEntity template) async {
    return await repository.createTemplate(template);
  }
}
