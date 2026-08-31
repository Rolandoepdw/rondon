import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/shifts/data/datasources/shift_template_local_datasource.dart';
import 'package:rondon/features/shifts/data/models/shift_template_model.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';

class ShiftTemplateRepositoryImpl implements IShiftTemplateRepository {
  final ShiftTemplateLocalDataSource localDataSource;

  ShiftTemplateRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<ShiftTemplateEntity>>> getActiveTemplates() async {
    try {
      final templates = await localDataSource.getActiveTemplates();
      return Right(List<ShiftTemplateEntity>.from(templates));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createTemplate(ShiftTemplateEntity template) async {
    try {
      await localDataSource.createTemplate(ShiftTemplateModel(
        id: template.id,
        name: template.name,
        startTime: template.startTime,
        endTime: template.endTime,
        allowedGender: template.allowedGender,
        targetQuota: template.targetQuota,
        minActiveProfiles: template.minActiveProfiles,
        displayOrder: template.displayOrder,
        isActive: template.isActive,
      ));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTemplate(ShiftTemplateEntity template) async {
    try {
      await localDataSource.updateTemplate(ShiftTemplateModel(
        id: template.id,
        name: template.name,
        startTime: template.startTime,
        endTime: template.endTime,
        allowedGender: template.allowedGender,
        targetQuota: template.targetQuota,
        minActiveProfiles: template.minActiveProfiles,
        displayOrder: template.displayOrder,
        isActive: template.isActive,
      ));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTemplate(String id) async {
    try {
      await localDataSource.deleteTemplate(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
