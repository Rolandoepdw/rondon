import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';

abstract class ISettingsRepository {
  Future<Either<Failure, int>> getMinDaysBetweenShifts();
  Future<Either<Failure, void>> setMinDaysBetweenShifts(int days);
  Future<Either<Failure, bool>> getAllowUnderQuota();
  Future<Either<Failure, void>> setAllowUnderQuota(bool allow);
}
