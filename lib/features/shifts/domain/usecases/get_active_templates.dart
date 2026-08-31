import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';

class GetActiveTemplates implements UseCase<List<ShiftTemplateEntity>, NoParams> {
  final IShiftTemplateRepository repository;

  GetActiveTemplates(this.repository);

  @override
  Future<Either<Failure, List<ShiftTemplateEntity>>> call(NoParams params) async {
    return await repository.getActiveTemplates();
  }
}
