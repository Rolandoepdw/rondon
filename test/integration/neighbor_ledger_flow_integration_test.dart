import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/neighbors/data/repositories/neighbor_repository_impl.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDatabase;
  late NeighborRepositoryImpl repository;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    final dbPath = await getDatabasesPath();
    await deleteDatabase(join(dbPath, 'rondon.db'));
    appDatabase = AppDatabase.instance;
    await appDatabase.close();
    repository = NeighborRepositoryImpl(appDatabase: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('End-to-End: Neighbor creation, trigger-based balance update via ledger, and delete restriction', () async {
    // 1. Create test neighbor
    const neighbor = NeighborEntity(
      id: 'n-test-1',
      fullName: 'Juan Pérez Integración',
      phone: '555-1234',
      gender: Gender.male,
      operationalProfile: OperationalProfile.active,
      balance: 0,
      isActive: true,
    );

    final createResult = await repository.createNeighbor(neighbor);
    expect(createResult.isRight(), true);

    // Verify initial balance is 0
    final fetchedBefore = await repository.getNeighborById('n-test-1');
    expect(fetchedBefore.isRight(), true);
    expect(fetchedBefore.getOrElse(() => null)?.balance, 0);

    // 2. Update balance (Absence -> delta -1)
    final updateBalanceResult = await repository.updateBalance(
      neighborId: 'n-test-1',
      delta: -1,
      reason: LedgerReason.inasistencia,
      notes: 'Test unexcused absence',
    );
    expect(updateBalanceResult.isRight(), true);

    // 3. Verify SQLite Trigger automatically updated neighbors.balance to -1
    final fetchedAfter = await repository.getNeighborById('n-test-1');
    expect(fetchedAfter.getOrElse(() => null)?.balance, -1);

    // 4. Verify ledger history
    final ledgerResult = await repository.getLedgerHistory('n-test-1');
    expect(ledgerResult.isRight(), true);
    final history = ledgerResult.getOrElse(() => []);
    expect(history.length, 1);
    expect(history.first.delta, -1);
    expect(history.first.reason, LedgerReason.inasistencia);

    // 5. Try deleting the neighbor (Should fail due to ON DELETE RESTRICT on ledger)
    final deleteResult = await repository.deleteNeighbor('n-test-1');
    expect(deleteResult.isLeft(), true);
  });
}
