import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';
import 'package:rondon/features/neighbors/domain/repositories/base_squad_repository.dart';
import 'package:rondon/features/neighbors/domain/entities/base_squad.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_template_repository.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';

class GenerateCycleSchedule implements UseCase<void, GenerateParams> {
  final INeighborRepository neighborRepository;
  final IBaseSquadRepository squadRepository;
  final IShiftTemplateRepository templateRepository;
  final IShiftRepository shiftRepository;
  final ISettingsRepository settingsRepository;

  GenerateCycleSchedule({
    required this.neighborRepository,
    required this.squadRepository,
    required this.templateRepository,
    required this.shiftRepository,
    required this.settingsRepository,
  });

  @override
  Future<Either<Failure, void>> call(GenerateParams params) async {
    // 1. Obtener todos los datos necesarios
    final templatesEither = await templateRepository.getActiveTemplates();
    final squadsEither = await squadRepository.getAllSquads();
    final neighborsEither = await neighborRepository.getAllNeighbors(onlyActive: true);
    final minDaysEither = await settingsRepository.getMinDaysBetweenShifts();

    return templatesEither.fold(
      (l) => Left(l),
      (templates) => squadsEither.fold(
        (l) => Left(l),
        (squads) => neighborsEither.fold(
          (l) => Left(l),
          (allNeighbors) => minDaysEither.fold(
            (l) => Left(l),
            (minDays) async {
              if (templates.isEmpty) return const Left(DatabaseFailure('No hay plantillas activas'));

              // Mapa para rastrear la última fecha de guardia de cada vecino (incluyendo las que estamos generando)
              Map<String, DateTime> lastShiftDates = {};
              for (var n in allNeighbors) {
                final lastDateEither = await shiftRepository.getLastCompletedShiftDate(n.id, params.startDate);
                lastDateEither.fold((_) => null, (date) {
                  if (date != null) lastShiftDates[n.id] = date;
                });
              }

              // Mapa para llevar la rotación de cuadrillas por plantilla
              // (Simplificación: Usamos una rotación simple basada en el orden de la lista)
              Map<String, int> squadRotationIndices = {};
              for (var t in templates) {
                squadRotationIndices[t.id] = 0;
              }

              List<ScheduledShiftEntity> generatedShifts = [];
              DateTime currentDate = params.startDate;

              while (currentDate.isBefore(params.endDate) || currentDate.isAtSameMomentAs(params.endDate)) {
                for (var template in templates) {
                  final shiftId = const Uuid().v4();
                  List<ShiftAssignmentEntity> assignments = [];

                  // 2. Asignación de Cuadrilla Base
                  // Buscamos cuadrillas asociadas a esta plantilla o rotativas
                  final eligibleSquads = squads.where((s) => s.shiftTemplateId == template.id || s.shiftTemplateId == null).toList();
                  
                  if (eligibleSquads.isNotEmpty) {
                    // Intentamos asignar la siguiente cuadrilla en la rotación que cumpla el descanso
                    int startIndex = squadRotationIndices[template.id] ?? 0;
                    BaseSquadEntity? selectedSquad;

                    for (int i = 0; i < eligibleSquads.length; i++) {
                      final idx = (startIndex + i) % eligibleSquads.length;
                      final candidateSquad = eligibleSquads[idx];
                      
                      bool squadCanWork = true;
                      for (var member in candidateSquad.members) {
                        if (!_passesRestPeriod(member.id, currentDate, minDays, lastShiftDates)) {
                          squadCanWork = false;
                          break;
                        }
                      }

                      if (squadCanWork) {
                        selectedSquad = candidateSquad;
                        squadRotationIndices[template.id] = (idx + 1) % eligibleSquads.length;
                        break;
                      }
                    }

                    if (selectedSquad != null) {
                      for (var member in selectedSquad.members) {
                        assignments.add(_createAssignment(shiftId, member, template, isSubstitute: false));
                        lastShiftDates[member.id] = currentDate;
                      }
                    }
                  }

                  // 3. Cobertura de Vacantes
                  int vacancies = template.targetQuota - assignments.length;
                  if (vacancies > 0) {
                    final candidates = allNeighbors.where((n) {
                      return !assignments.any((a) => a.neighborId == n.id) &&
                             _passesRestPeriod(n.id, currentDate, minDays, lastShiftDates) &&
                             _isGenderCompatible(n, template);
                    }).toList();

                    // Ordenamiento Fair-Share:
                    // 1. Deuda (balance < 0) - Los deudores primero
                    // 2. Mayor descanso (días desde la última guardia)
                    // 3. Alfabético
                    candidates.sort((a, b) {
                      if (a.balance != b.balance) return a.balance.compareTo(b.balance);
                      final dateA = lastShiftDates[a.id] ?? DateTime(2000);
                      final dateB = lastShiftDates[b.id] ?? DateTime(2000);
                      return dateA.compareTo(dateB);
                    });

                    for (var candidate in candidates.take(vacancies)) {
                      assignments.add(_createAssignment(shiftId, candidate, template, isSubstitute: true));
                      lastShiftDates[candidate.id] = currentDate;
                    }
                  }

                  // 4. Verificación de Seguridad (Mínimo Activos)
                  int activeCount = assignments.where((a) => a.effectiveOperationalProfile == OperationalProfile.activo).length;
                  if (activeCount < template.minActiveProfiles) {
                    // Intentar reemplazar miembros de APOYO por ACTIVOS disponibles
                    int needed = template.minActiveProfiles - activeCount;
                    
                    final activeCandidates = allNeighbors.where((n) {
                      return n.operationalProfile == OperationalProfile.activo &&
                             !assignments.any((a) => a.neighborId == n.id) &&
                             _passesRestPeriod(n.id, currentDate, minDays, lastShiftDates) &&
                             _isGenderCompatible(n, template);
                    }).toList();

                    activeCandidates.sort((a, b) {
                      if (a.balance != b.balance) return a.balance.compareTo(b.balance);
                      final dateA = lastShiftDates[a.id] ?? DateTime(2000);
                      final dateB = lastShiftDates[b.id] ?? DateTime(2000);
                      return dateA.compareTo(dateB);
                    });

                    for (var candidate in activeCandidates.take(needed)) {
                      // Buscar un miembro de APOYO para reemplazar
                      int supportIdx = assignments.indexWhere((a) => a.effectiveOperationalProfile == OperationalProfile.apoyo);
                      if (supportIdx != -1) {
                        final replaced = assignments[supportIdx];
                        lastShiftDates.remove(replaced.neighborId); // Ya no trabaja hoy
                        
                        assignments[supportIdx] = _createAssignment(shiftId, candidate, template, isSubstitute: true);
                        lastShiftDates[candidate.id] = currentDate;
                      } else {
                        // Si no hay apoyo para reemplazar pero falta seguridad, lo añadimos como extra si hay cupo o forzamos
                        assignments.add(_createAssignment(shiftId, candidate, template, isSubstitute: true));
                        lastShiftDates[candidate.id] = currentDate;
                      }
                    }
                  }

                  generatedShifts.add(ScheduledShiftEntity(
                    id: shiftId,
                    date: currentDate,
                    shiftTemplateId: template.id,
                    template: template,
                    status: ShiftStatus.planificado,
                    assignments: assignments,
                  ));
                }
                currentDate = currentDate.add(const Duration(days: 1));
              }

              // Guardar en DB
              return await shiftRepository.saveGeneratedShifts(generatedShifts);
            },
          ),
        ),
      ),
    );
  }

  bool _passesRestPeriod(String neighborId, DateTime targetDate, int minDays, Map<String, DateTime> lastShiftDates) {
    final lastDate = lastShiftDates[neighborId];
    if (lastDate == null) return true;
    return targetDate.difference(lastDate).inDays > minDays;
  }

  bool _isGenderCompatible(NeighborEntity neighbor, ShiftTemplateEntity template) {
    if (template.allowedGender == AllowedGenderPolicy.mixto) return true;
    if (template.allowedGender == AllowedGenderPolicy.soloHombres && neighbor.gender == Gender.masculino) return true;
    if (template.allowedGender == AllowedGenderPolicy.soloMujeres && neighbor.gender == Gender.femenino) return true;
    return false;
  }

  ShiftAssignmentEntity _createAssignment(String shiftId, NeighborEntity neighbor, ShiftTemplateEntity template, {required bool isSubstitute}) {
    // Lógica de excepción operativa: mujer en turno de hombres es APOYO
    OperationalProfile effectiveProfile = neighbor.operationalProfile;
    if (template.allowedGender == AllowedGenderPolicy.soloHombres && neighbor.gender == Gender.femenino) {
      effectiveProfile = OperationalProfile.apoyo;
    }

    return ShiftAssignmentEntity(
      id: const Uuid().v4(),
      scheduledShiftId: shiftId,
      neighborId: neighbor.id,
      neighbor: neighbor,
      isSubstitute: isSubstitute,
      attendanceStatus: AttendanceStatus.pendiente,
      effectiveOperationalProfile: effectiveProfile,
      balanceImpacted: false,
    );
  }
}

class GenerateParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const GenerateParams({required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
