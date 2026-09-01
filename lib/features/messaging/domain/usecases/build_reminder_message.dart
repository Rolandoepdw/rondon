import 'package:intl/intl.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';

class BuildReminderMessage {
  String call(ScheduledShiftEntity shift, ShiftAssignmentEntity assignment) {
    final neighbor = assignment.neighbor;
    if (neighbor == null) return '';

    final dateStr = DateFormat('EEEE d de MMMM', 'es_ES').format(shift.date);
    final companions = shift.assignments
        .where((a) => a.neighborId != neighbor.id)
        .map((a) => a.neighbor?.fullName ?? 'S/N')
        .join(', ');

    return '''
🚨 *RECORDATORIO DE GUARDIA VECINAL* 🚨

Hola *${neighbor.fullName}*, te recordamos tu compromiso para la guardia comunitaria de seguridad:

📅 *Fecha:* $dateStr
⏰ *Horario:* ${shift.template?.startTime} a ${shift.template?.endTime} (${shift.template?.name})
👥 *Tus compañeros de turno:* $companions
📌 *Condición:* ${assignment.isSubstitute ? 'Refuerzo/Sustitución' : 'Titular'}

Por favor, confirma que estás listo respondiendo a este mensaje. En caso de fuerza mayor que te impida asistir, avisa de inmediato para coordinar tu reemplazo.

¡Gracias por cuidar nuestro barrio! 🛡️
''';
  }

  String buildBroadcast(ScheduledShiftEntity shift) {
    final dateStr = DateFormat('EEEE d de MMMM', 'es_ES').format(shift.date);
    final listado = shift.assignments.map((a) {
      return '• ${a.neighbor?.fullName ?? 'Desconocido'} (${a.isSubstitute ? 'Refuerzo' : 'Titular'})';
    }).join('\n');

    return '''
📢 *CRONOGRAMA DE GUARDIAS - $dateStr* 📢

Estimados vecinos, compartimos las cuadrillas de seguridad asignadas para esta noche en el *${shift.template?.name}* (${shift.template?.startTime} a ${shift.template?.endTime}):

$listado

Agradecemos a todos los vecinos asignados su puntualidad y compromiso con la seguridad de la comunidad. 🛡️
''';
  }
}
