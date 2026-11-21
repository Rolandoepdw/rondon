import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/utils/app_logger.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';

class ShiftRepositoryImpl implements IShiftRepository {
  final AppDatabase appDatabase;

  ShiftRepositoryImpl({required this.appDatabase});

  @override
  Future<Either<Failure, List<ScheduledShiftEntity>>> getShiftsByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await appDatabase.database;
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      AppLogger.read('SHIFTS', 'Fetching shifts between $startStr and $endStr');

      final shiftsResult = await db.query(
        'scheduled_shifts',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startStr, endStr],
        orderBy: 'date ASC',
      );

      List<ScheduledShiftEntity> shifts = [];
      for (var shiftMap in shiftsResult) {
        final assignments = await _getAssignmentsForShift(db, shiftMap['id'] as String);
        final template = await _getTemplateById(db, shiftMap['shift_template_id'] as String);
        shifts.add(ScheduledShiftEntity.fromMap(shiftMap, template: template, assignments: assignments));
      }

      return Right(shifts);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScheduledShiftEntity?>> getShiftById(String id) async {
    try {
      final db = await appDatabase.database;
      AppLogger.read('SHIFTS', 'Fetching shift by ID: $id');
      final result = await db.query('scheduled_shifts', where: 'id = ?', whereArgs: [id]);

      if (result.isEmpty) return const Right(null);

      final assignments = await _getAssignmentsForShift(db, id);
      final template = await _getTemplateById(db, result.first['shift_template_id'] as String);
      return Right(ScheduledShiftEntity.fromMap(result.first, template: template, assignments: assignments));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveGeneratedShifts(List<ScheduledShiftEntity> shifts) async {
    try {
      final db = await appDatabase.database;
      AppLogger.create('SHIFTS', 'Saving ${shifts.length} generated shifts');
      await db.transaction((txn) async {
        for (var shift in shifts) {
          await txn.insert('scheduled_shifts', shift.toMap());
          for (var assignment in shift.assignments) {
            await txn.insert('shift_assignments', assignment.toMap());
          }
        }
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> executeSubstitution({
    required String shiftId,
    required String originalNeighborId,
    required String? substituteNeighborId,
    required OperationalProfile effectiveProfile,
  }) async {
    try {
      final db = await appDatabase.database;
      AppLogger.update('SHIFTS', 'Executing substitution in shift $shiftId');
      await db.transaction((txn) async {
        await txn.update(
          'shift_assignments',
          {'attendance_status': 'FALTA', 'balance_impacted': 1},
          where: 'scheduled_shift_id = ? AND neighbor_id = ?',
          whereArgs: [shiftId, originalNeighborId],
        );

        AppLogger.create('LEDGER', 'Penalizing original neighbor $originalNeighborId due to substitution');
        await txn.insert('balance_ledger_records', {
          'id': const Uuid().v4(),
          'neighbor_id': originalNeighborId,
          'scheduled_shift_id': shiftId,
          'delta': -1,
          'reason': 'INASISTENCIA',
        });

        if (substituteNeighborId != null) {
          AppLogger.create('SHIFTS', 'Assigning substitute $substituteNeighborId to shift $shiftId');
          final newAssignment = ShiftAssignmentEntity(
            id: const Uuid().v4(),
            scheduledShiftId: shiftId,
            neighborId: substituteNeighborId,
            isSubstitute: true,
            substituteForNeighborId: originalNeighborId,
            attendanceStatus: AttendanceStatus.pendiente,
            effectiveOperationalProfile: effectiveProfile,
            balanceImpacted: false,
          );
          await txn.insert('shift_assignments', newAssignment.toMap());
        }

        await txn.update('scheduled_shifts', {'status': 'REPLANIFICADO'}, where: 'id = ?', whereArgs: [shiftId]);
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> auditShiftAttendance({
    required String shiftId,
    required Map<String, AttendanceStatus> attendanceMap,
    String? notes,
  }) async {
    try {
      final db = await appDatabase.database;
      AppLogger.update('SHIFTS', 'Auditing attendance for shift $shiftId');
      await db.transaction((txn) async {
        for (var entry in attendanceMap.entries) {
          final neighborId = entry.key;
          final status = entry.value;

          final assignmentResult = await txn.query(
            'shift_assignments',
            where: 'scheduled_shift_id = ? AND neighbor_id = ?',
            whereArgs: [shiftId, neighborId],
          );

          if (assignmentResult.isEmpty) continue;

          final isAlreadyImpacted = (assignmentResult.first['balance_impacted'] as int) == 1;
          final isSubstitute = (assignmentResult.first['is_substitute'] as int) == 1;

          if (status == AttendanceStatus.presente) {
            if (isSubstitute) {
              final neighborResult = await txn.query('neighbors', columns: ['balance'], where: 'id = ?', whereArgs: [neighborId]);
              if (neighborResult.isNotEmpty) {
                final currentBalance = neighborResult.first['balance'] as int;
                final reason = currentBalance < 0 
                    ? 'RECUPERACION_DEUDA' 
                    : 'COBERTURA_VOLUNTARIA';

                AppLogger.create('LEDGER', 'Rewarding substitute $neighborId (Reason: $reason)');
                await txn.insert('balance_ledger_records', {
                  'id': const Uuid().v4(),
                  'neighbor_id': neighborId,
                  'scheduled_shift_id': shiftId,
                  'delta': 1,
                  'reason': reason,
                });
              }
            }
          } else if (status == AttendanceStatus.falta && !isAlreadyImpacted) {
            AppLogger.create('LEDGER', 'Penalizing absence for $neighborId');
            await txn.insert('balance_ledger_records', {
              'id': const Uuid().v4(),
              'neighbor_id': neighborId,
              'scheduled_shift_id': shiftId,
              'delta': -1,
              'reason': 'INASISTENCIA',
            });
          }

          await txn.update(
            'shift_assignments',
            {'attendance_status': status.value, 'balance_impacted': 1},
            where: 'scheduled_shift_id = ? AND neighbor_id = ?',
            whereArgs: [shiftId, neighborId],
          );
        }

        await txn.update(
          'scheduled_shifts', 
          {
            'status': 'AUDITADO',
            'notes': notes,
          }, 
          where: 'id = ?', 
          whereArgs: [shiftId]
        );
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastCompletedShiftDate(String neighborId, DateTime beforeDate) async {
    try {
      final db = await appDatabase.database;
      final beforeStr = beforeDate.toIso8601String().split('T')[0];

      final result = await db.rawQuery('''
        SELECT s.date 
        FROM scheduled_shifts s
        JOIN shift_assignments a ON s.id = a.scheduled_shift_id
        WHERE a.neighbor_id = ? 
          AND a.attendance_status = 'PRESENTE'
          AND s.date < ?
        ORDER BY s.date DESC
        LIMIT 1
      ''', [neighborId, beforeStr]);

      if (result.isNotEmpty) {
        return Right(DateTime.parse(result.first['date'] as String));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // Helpers
  Future<List<ShiftAssignmentEntity>> _getAssignmentsForShift(Database db, String shiftId) async {
    final result = await db.rawQuery('''
      SELECT a.*, n.full_name, n.phone, n.gender, n.operational_profile, n.balance, n.is_active, n.notes as neighbor_notes
      FROM shift_assignments a
      JOIN neighbors n ON a.neighbor_id = n.id
      WHERE a.scheduled_shift_id = ?
    ''', [shiftId]);

    return result.map((map) {
      final neighbor = NeighborEntity.fromMap({
        'id': map['neighbor_id'],
        'full_name': map['full_name'],
        'phone': map['phone'],
        'gender': map['gender'],
        'operational_profile': map['operational_profile'],
        'balance': map['balance'],
        'is_active': map['is_active'],
        'notes': map['neighbor_notes'],
      });
      return ShiftAssignmentEntity.fromMap(map, neighbor: neighbor);
    }).toList();
  }

  Future<ShiftTemplateEntity?> _getTemplateById(Database db, String id) async {
    final result = await db.query('shift_templates', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return ShiftTemplateEntity.fromMap(result.first);
    return null;
  }
}
