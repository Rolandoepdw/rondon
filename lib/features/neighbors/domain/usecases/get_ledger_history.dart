import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/balance_ledger_record.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

class GetLedgerHistory implements UseCase<List<BalanceLedgerRecordEntity>, String> {
  final INeighborRepository repository;

  GetLedgerHistory(this.repository);

  @override
  Future<Either<Failure, List<BalanceLedgerRecordEntity>>> call(String neighborId) async {
    return await repository.getLedgerHistory(neighborId);
  }
}
