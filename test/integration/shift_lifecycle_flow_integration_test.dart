import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/core/utils/database_seeder.dart';
import 'package:rondon/features/shifts/data/repositories/shift_repository_impl.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDatabase;
  late ShiftRepositoryImpl shiftRepository;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    final dbPath = await getDatabasesPath();
    await deleteDatabase(join(dbPath, 'rondon.db'));
    appDatabase = AppDatabase.instance;
    await appDatabase.close();
    shiftRepository = ShiftRepositoryImpl(appDatabase: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('Shift Lifecycle: Seeding, scheduling, and auditing attendance with balance impact', () async {
    // 1. Seed database
    await DatabaseSeeder.seedDatabase();

    final db = await appDatabase.database;
    final templates = await db.query('shift_templates');
    final templateId = templates.first['id'] as String;
    
    // Insert a dedicated test neighbor with balance = 0 to make test deterministic
    const neighborId = 'n-shift-test';
    await db.insert('neighbors', {
      'id': neighborId,
      'full_name': 'Vecino Turno Test',
      'gender': 'MALE',
      'operational_profile': 'ACTIVE',
      'balance': 0,
      'is_active': 1,
    });

    const shiftId = 'shift-test-1';
    await db.insert('scheduled_shifts', {
      'id': shiftId,
      'date': '2026-10-18',
      'shift_template_id': templateId,
      'status': 'PLANIFICADO',
    });

    await db.insert('shift_assignments', {
      'id': 'assign-1',
      'scheduled_shift_id': shiftId,
      'neighbor_id': neighborId,
      'is_substitute': 0,
      'attendance_status': 'PENDIENTE',
      'effective_operational_profile': 'ACTIVE',
      'balance_impacted': 0,
    });

    // 2. Audit attendance (mark absence)
    final auditResult = await shiftRepository.auditShiftAttendance(
      shiftId: shiftId,
      attendanceMap: {neighborId: AttendanceStatus.falta},
      notes: 'Integration test audit notes',
    );

    expect(auditResult.isRight(), true);

    // 3. Verify shift status and neighbor balance update via trigger
    final updatedShift = await shiftRepository.getShiftById(shiftId);
    expect(updatedShift.isRight(), true);
    expect(updatedShift.getOrElse(() => null)?.status, ShiftStatus.auditado);

    final neighborCheck = await db.query('neighbors', where: 'id = ?', whereArgs: [neighborId]);
    expect(neighborCheck.first['balance'], -1);
  });
}
