import 'package:dartz/dartz.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/entities/balance_ledger_record.dart';

enum LedgerReason {
  inasistencia('INASISTENCIA'),
  coberturaVoluntaria('COBERTURA_VOLUNTARIA'),
  recuperacionDeuda('RECUPERACION_DEUDA'),
  ajusteManualAdmin('AJUSTE_MANUAL_ADMIN');

  final String value;
  const LedgerReason(this.value);

  static LedgerReason fromString(String val) =>
      LedgerReason.values.firstWhere((e) => e.value == val);
}

abstract class INeighborRepository {
  Future<Either<Failure, List<NeighborEntity>>> getAllNeighbors({bool onlyActive = true});
  Future<Either<Failure, NeighborEntity?>> getNeighborById(String id);
  Future<Either<Failure, void>> createNeighbor(NeighborEntity neighbor);
  Future<Either<Failure, void>> updateNeighbor(NeighborEntity neighbor);
  Future<Either<Failure, void>> deleteNeighbor(String id);
  Future<Either<Failure, void>> updateBalance({
    required String neighborId,
    required int delta,
    required LedgerReason reason,
    String? shiftId,
    String? notes,
  });
  Future<Either<Failure, List<BalanceLedgerRecordEntity>>> getLedgerHistory(String neighborId);
}
