import 'package:uuid/uuid.dart';
import 'package:rondon/database/app_database.dart';
import 'package:rondon/features/shifts/data/models/scheduled_shift_model.dart';
import 'package:rondon/features/shifts/data/models/shift_assignment_model.dart';
import 'package:rondon/features/shifts/data/models/shift_template_model.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/data/models/neighbor_model.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart' as neighbor_repo;

abstract class ShiftLocalDataSource {
  Future<List<ScheduledShiftModel>> getShiftsByDateRange(DateTime start, DateTime end);
  Future<ScheduledShiftModel?> getShiftById(String id);
  Future<void> saveGeneratedShifts(List<ScheduledShiftModel> shifts);
  Future<void> executeSubstitution({
    required String shiftId,
    required String originalNeighborId,
    required String? substituteNeighborId,
    required OperationalProfile effectiveProfile,
  });
  Future<void> auditShiftAttendance({
    required String shiftId,
    required Map<String, AttendanceStatus> attendanceMap,
  });
  Future<DateTime?> getLastCompletedShiftDate(String neighborId, DateTime beforeDate);
}

class ShiftLocalDataSourceImpl implements ShiftLocalDataSource {
  final AppDatabase appDatabase;

  ShiftLocalDataSourceImpl({required this.appDatabase});

  @override
  Future<List<ScheduledShiftModel>> getShiftsByDateRange(DateTime start, DateTime end) async {
    final db = await appDatabase.database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final shiftsResult = await db.query(
      'scheduled_shifts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );

    List<ScheduledShiftModel> shifts = [];
    for (var shiftMap in shiftsResult) {
      final assignments = await _getAssignmentsForShift(shiftMap['id'] as String);
      final template = await _getTemplateById(shiftMap['shift_template_id'] as String);
      shifts.add(ScheduledShiftModel.fromMap(shiftMap, template: template, assignments: assignments));
    }

    return shifts;
  }

  @override
  Future<ScheduledShiftModel?> getShiftById(String id) async {
    final db = await appDatabase.database;
    final result = await db.query('scheduled_shifts', where: 'id = ?', whereArgs: [id]);

    if (result.isEmpty) return null;

    final assignments = await _getAssignmentsForShift(id);
    final template = await _getTemplateById(result.first['shift_template_id'] as String);
    return ScheduledShiftModel.fromMap(result.first, template: template, assignments: assignments);
  }

  @override
  Future<void> saveGeneratedShifts(List<ScheduledShiftModel> shifts) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      for (var shift in shifts) {
        await txn.insert('scheduled_shifts', shift.toMap());
        for (var assignment in shift.assignments) {
          final model = ShiftAssignmentModel(
            id: assignment.id,
            scheduledShiftId: assignment.scheduledShiftId,
            neighborId: assignment.neighborId,
            isSubstitute: assignment.isSubstitute,
            substituteForNeighborId: assignment.substituteForNeighborId,
            attendanceStatus: assignment.attendanceStatus,
            effectiveOperationalProfile: assignment.effectiveOperationalProfile,
            balanceImpacted: assignment.balanceImpacted,
          );
          await txn.insert('shift_assignments', model.toMap());
        }
      }
    });
  }

  @override
  Future<void> executeSubstitution({
    required String shiftId,
    required String originalNeighborId,
    required String? substituteNeighborId,
    required OperationalProfile effectiveProfile,
  }) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      // 1. Marcar falta del original e impactar balance inmediatamente (Regla de negocio)
      await txn.update(
        'shift_assignments',
        {'attendance_status': 'FALTA', 'balance_impacted': 1},
        where: 'scheduled_shift_id = ? AND neighbor_id = ?',
        whereArgs: [shiftId, originalNeighborId],
      );

      // Decrementar balance original
      final original = await txn.query('neighbors', columns: ['balance'], where: 'id = ?', whereArgs: [originalNeighborId]);
      if (original.isNotEmpty) {
        final currentBalance = original.first['balance'] as int;
        await txn.update('neighbors', {'balance': currentBalance - 1}, where: 'id = ?', whereArgs: [originalNeighborId]);
        
        await txn.insert('balance_ledger_records', {
          'id': const Uuid().v4(),
          'neighbor_id': originalNeighborId,
          'scheduled_shift_id': shiftId,
          'delta': -1,
          'reason': 'INASISTENCIA',
        });
      }

      // 2. Insertar sustituto si existe
      if (substituteNeighborId != null) {
        final newAssignment = ShiftAssignmentModel(
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

      // 3. Actualizar estado del turno a REPLANIFICADO
      await txn.update('scheduled_shifts', {'status': 'REPLANIFICADO'}, where: 'id = ?', whereArgs: [shiftId]);
    });
  }

  @override
  Future<void> auditShiftAttendance({
    required String shiftId,
    required Map<String, AttendanceStatus> attendanceMap,
  }) async {
    final db = await appDatabase.database;
    await db.transaction((txn) async {
      for (var entry in attendanceMap.entries) {
        final neighborId = entry.key;
        final status = entry.value;

        // Obtener datos de la asignación actual
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
            // Incrementar balance del sustituto
            final neighborResult = await txn.query('neighbors', columns: ['balance'], where: 'id = ?', whereArgs: [neighborId]);
            if (neighborResult.isNotEmpty) {
              final currentBalance = neighborResult.first['balance'] as int;
              await txn.update('neighbors', {'balance': currentBalance + 1}, where: 'id = ?', whereArgs: [neighborId]);
              
              final reason = currentBalance < 0 
                  ? neighbor_repo.LedgerReason.recuperacionDeuda.value 
                  : neighbor_repo.LedgerReason.coberturaVoluntaria.value;

              await txn.insert('balance_ledger_records', {
                'id': const Uuid().v4(),
                'neighbor_id': neighborId,
                'scheduled_shift_id': shiftId,
                'delta': 1,
                'reason': reason,
              });
            }
          }
          // Si es titular presente, no hay cambio de balance.
        } else if (status == AttendanceStatus.falta && !isAlreadyImpacted) {
          // Penalizar si no fue penalizado antes (ej: falta sin aviso)
          final neighborResult = await txn.query('neighbors', columns: ['balance'], where: 'id = ?', whereArgs: [neighborId]);
          if (neighborResult.isNotEmpty) {
            final currentBalance = neighborResult.first['balance'] as int;
            await txn.update('neighbors', {'balance': currentBalance - 1}, where: 'id = ?', whereArgs: [neighborId]);
            
            await txn.insert('balance_ledger_records', {
              'id': const Uuid().v4(),
              'neighbor_id': neighborId,
              'scheduled_shift_id': shiftId,
              'delta': -1,
              'reason': 'INASISTENCIA',
            });
          }
        }

        // Actualizar estado de la asignación
        await txn.update(
          'shift_assignments',
          {'attendance_status': status.value, 'balance_impacted': 1},
          where: 'scheduled_shift_id = ? AND neighbor_id = ?',
          whereArgs: [shiftId, neighborId],
        );
      }

      // Marcar turno como AUDITADO
      await txn.update('scheduled_shifts', {'status': 'AUDITADO'}, where: 'id = ?', whereArgs: [shiftId]);
    });
  }

  @override
  Future<DateTime?> getLastCompletedShiftDate(String neighborId, DateTime beforeDate) async {
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
      return DateTime.parse(result.first['date'] as String);
    }
    return null;
  }

  // Helpers
  Future<List<ShiftAssignmentEntity>> _getAssignmentsForShift(String shiftId) async {
    final db = await appDatabase.database;
    final result = await db.rawQuery('''
      SELECT a.*, n.full_name, n.phone, n.gender, n.operational_profile, n.balance, n.is_active, n.notes as neighbor_notes
      FROM shift_assignments a
      JOIN neighbors n ON a.neighbor_id = n.id
      WHERE a.scheduled_shift_id = ?
    ''', [shiftId]);

    return result.map((map) {
      final neighbor = NeighborModel.fromMap({
        'id': map['neighbor_id'],
        'full_name': map['full_name'],
        'phone': map['phone'],
        'gender': map['gender'],
        'operational_profile': map['operational_profile'],
        'balance': map['balance'],
        'is_active': map['is_active'],
        'notes': map['neighbor_notes'],
      });
      return ShiftAssignmentModel.fromMap(map, neighbor: neighbor);
    }).toList();
  }

  Future<ShiftTemplateModel?> _getTemplateById(String id) async {
    final db = await appDatabase.database;
    final result = await db.query('shift_templates', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return ShiftTemplateModel.fromMap(result.first);
    return null;
  }
}
