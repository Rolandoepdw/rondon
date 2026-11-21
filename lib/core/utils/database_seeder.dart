import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/core/utils/app_logger.dart';

class DatabaseSeeder {
  static Future<void> clearDatabase() async {
    final db = await AppDatabase.instance.database;
    AppLogger.delete('SEEDER', 'Clearing all database tables...');
    await db.transaction((txn) async {
      await txn.delete('balance_ledger_records');
      await txn.delete('shift_assignments');
      await txn.delete('scheduled_shifts');
      await txn.delete('neighbors');
      await txn.delete('base_squads');
      await txn.delete('shift_templates');
    });
  }

  static Future<void> seedDatabase() async {
    await clearDatabase();
    final db = await AppDatabase.instance.database;
    final uuid = const Uuid();
    final random = Random();

    AppLogger.info('SEEDER', 'Starting database seeding process...');

    await db.transaction((txn) async {
      // 1. Plantillas de Turno
      AppLogger.create('SEEDER', 'Seeding shift templates...');
      final t1Id = uuid.v4();
      final t2Id = uuid.v4();
      final t3Id = uuid.v4();

      await txn.insert('shift_templates', {
        'id': t1Id,
        'name': 'Turno Temprano (Mixto)',
        'start_time': '20:00',
        'end_time': '00:00',
        'allowed_gender': 'MIXED',
        'target_quota': 3,
        'min_active_profiles': 1,
        'display_order': 1,
        'is_active': 1,
      });

      await txn.insert('shift_templates', {
        'id': t2Id,
        'name': 'Turno Madrugada (Hombres)',
        'start_time': '00:00',
        'end_time': '04:00',
        'allowed_gender': 'MALE_ONLY',
        'target_quota': 3,
        'min_active_profiles': 1,
        'display_order': 2,
        'is_active': 1,
      });

      await txn.insert('shift_templates', {
        'id': t3Id,
        'name': 'Turno Especial (Mujeres)',
        'start_time': '18:00',
        'end_time': '22:00',
        'allowed_gender': 'FEMALE_ONLY',
        'target_quota': 2,
        'min_active_profiles': 1,
        'display_order': 3,
        'is_active': 1,
      });

      // 2. Cuadrillas (10 cuadrillas)
      AppLogger.create('SEEDER', 'Seeding 10 base squads...');
      List<String> squadIds = [];
      for (int i = 1; i <= 10; i++) {
        final sId = uuid.v4();
        squadIds.add(sId);
        await txn.insert('base_squads', {
          'id': sId,
          'name': 'Cuadrilla #$i',
          'shift_template_id': i % 3 == 0 ? t1Id : (i % 3 == 1 ? t2Id : null),
        });
      }

      // 3. Vecinos (60 personas)
      AppLogger.create('SEEDER', 'Seeding 60 neighbors and their ledger history...');
      final firstNames = ['Juan', 'María', 'Carlos', 'Ana', 'Luis', 'Elena', 'Pedro', 'Sofía', 'Miguel', 'Lucía', 'Jorge', 'Carmen', 'Roberto', 'Isabel', 'Fernando', 'Rosa', 'Antonio', 'Silvia', 'Manuel', 'Beatriz', 'Ricardo', 'Teresa', 'Francisco', 'Patricia', 'Daniela', 'Julio', 'Esther', 'Hugo', 'Alicia', 'Victor'];
      final lastNames = ['Pérez', 'García', 'Rodríguez', 'Martínez', 'López', 'Sánchez', 'Gómez', 'Díaz', 'Fernández', 'Ruiz', 'Morales', 'Castro', 'Ortiz', 'Silva', 'Vega', 'Ramos', 'Flores', 'Reyes', 'Castillo', 'Jiménez', 'Moreno', 'Molina', 'Ortega', 'Delgado', 'Ríos', 'Peralta', 'Luna', 'Medina', 'Guzmán', 'Navarro'];

      for (int i = 0; i < 60; i++) {
        final nId = uuid.v4();
        final firstName = firstNames[random.nextInt(firstNames.length)];
        final lastName = lastNames[random.nextInt(lastNames.length)];
        final isMale = random.nextBool();
        final isActive = random.nextDouble() > 0.25; // 75% activos
        final squadId = i < 40 ? squadIds[i ~/ 4] : null; // Primeros 40 en cuadrillas (4 por cuadrilla)
        
        int initialBalance = 0;
        if (random.nextDouble() > 0.7) initialBalance = -random.nextInt(4) - 1; // Algunos con deuda

        await txn.insert('neighbors', {
          'id': nId,
          'full_name': '$firstName $lastName ${i + 1}',
          'phone': '555-${1000 + i}',
          'gender': isMale ? 'MALE' : 'FEMALE',
          'operational_profile': isActive ? 'ACTIVE' : 'SUPPORT',
          'base_squad_id': squadId,
          'balance': 0, // Initialized at 0; triggers will update it if ledger records are inserted
          'is_active': 1,
          'notes': i % 10 == 0 ? 'Vecino de interés' : null,
        });

        if (initialBalance != 0) {
          await txn.insert('balance_ledger_records', {
            'id': uuid.v4(),
            'neighbor_id': nId,
            'scheduled_shift_id': null,
            'delta': initialBalance,
            'reason': 'AJUSTE_MANUAL_ADMIN',
            'notes': 'Saldo inicial sembrado (Balance de prueba)',
          });
        }
      }
      AppLogger.info('SEEDER', 'Database seeding process finished successfully');
    });
  }
}
