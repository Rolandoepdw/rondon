import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';

class DeleteShiftTemplate implements UseCase<void, String> {
  final IShiftTemplateRepository repository;

  DeleteShiftTemplate(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteTemplate(id);
  }
}
