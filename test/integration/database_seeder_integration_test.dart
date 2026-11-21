import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/core/utils/database_seeder.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDatabase;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    final dbPath = await getDatabasesPath();
    await deleteDatabase(join(dbPath, 'rondon.db'));
    appDatabase = AppDatabase.instance;
    await appDatabase.close();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('DatabaseSeeder populates templates, squads, and neighbors successfully', () async {
    // Act
    await DatabaseSeeder.seedDatabase();

    // Assert
    final db = await appDatabase.database;

    final templates = await db.query('shift_templates');
    expect(templates.length, 3);

    final squads = await db.query('base_squads');
    expect(squads.length, 10);

    final neighbors = await db.query('neighbors');
    expect(neighbors.length, 60);

    final ledgerRecords = await db.query('balance_ledger_records');
    expect(ledgerRecords.isNotEmpty, true);
  });
}
