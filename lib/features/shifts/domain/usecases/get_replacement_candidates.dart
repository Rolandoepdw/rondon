import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rondon/core/error/failures.dart';
import 'package:rondon/core/usecases/usecase.dart';
import 'package:rondon/features/neighbors/domain/entities/neighbor.dart';
import 'package:rondon/features/neighbors/domain/repositories/neighbor_repository.dart';
import 'package:rondon/features/shifts/domain/entities/scheduled_shift.dart';
import 'package:rondon/features/shifts/domain/entities/shift_template.dart';
import 'package:rondon/features/shifts/domain/repositories/shift_repository.dart';
import 'package:rondon/features/settings/domain/repositories/settings_repository.dart';

class GetReplacementCandidates implements UseCase<List<NeighborCandidate>, ReplacementParams> {
  final INeighborRepository neighborRepository;
  final IShiftRepository shiftRepository;
  final ISettingsRepository settingsRepository;

  GetReplacementCandidates({
    required this.neighborRepository,
    required this.shiftRepository,
    required this.settingsRepository,
  });

  @override
  Future<Either<Failure, List<NeighborCandidate>>> call(ReplacementParams params) async {
    // 1. Obtener datos base
    final minDaysEither = await settingsRepository.getMinDaysBetweenShifts();
    final neighborsEither = await neighborRepository.getAllNeighbors(onlyActive: true);
    final shiftEither = await shiftRepository.getShiftById(params.shiftId);

    return minDaysEither.fold(
      (l) => Left(l),
      (minDays) => neighborsEither.fold(
        (l) => Left(l),
        (allNeighbors) => shiftEither.fold(
          (l) => Left(l),
          (shift) async {
            if (shift == null) return const Left(DatabaseFailure('Turno no encontrado'));

            final targetDate = shift.date;
            List<NeighborCandidate> eligible = [];

            for (var neighbor in allNeighbors) {
              // Etapa 1: Filtros Fuertes
              // a) No ser el mismo que se reemplaza
              if (neighbor.id == params.originalNeighborId) continue;

              // b) Compatibilidad de Género
              final effectiveProfile = _calculateEffectiveProfile(neighbor, shift);
              
              // c) Descanso Mínimo y No estar ya asignado hoy
              final lastShiftDateEither = await shiftRepository.getLastCompletedShiftDate(neighbor.id, targetDate);
              
              bool passesRest = true;
              if (lastShiftDateEither is Right<Failure, DateTime?>) {
                final lastDate = lastShiftDateEither.value;
                if (lastDate != null) {
                  if (targetDate.difference(lastDate).inDays <= minDays) {
                    passesRest = false;
                  }
                }
              }

              // d) Verificar si ya tiene otra asignación en la misma fecha (aunque sea en otro turno)
              // (Simplificación: para este prototipo asumimos que getLastCompletedShiftDate o similar 
              // podría chequear asignaciones futuras/presentes. Por ahora validamos descanso pasado).

              if (passesRest) {
                eligible.add(NeighborCandidate(
                  neighbor: neighbor,
                  lastShiftDate: lastShiftDateEither.getOrElse(() => null),
                  effectiveProfile: effectiveProfile,
                ));
              }
            }

            // Etapa 2: Simulación de Seguridad Operativa
            // (Se deja para la UI mostrar advertencia si no hay suficientes ACTIVOS)

            // Etapa 3: Ordenamiento Multicriterio
            eligible.sort((a, b) => _compareCandidates(a, b, targetDate));

            return Right(eligible);
          },
        ),
      ),
    );
  }

  OperationalProfile _calculateEffectiveProfile(NeighborEntity neighbor, ScheduledShiftEntity shift) {
    if (shift.template?.allowedGender == AllowedGenderPolicy.maleOnly &&
        neighbor.gender == Gender.female) {
      return OperationalProfile.support;
    }
    return neighbor.operationalProfile;
  }

  int _compareCandidates(NeighborCandidate a, NeighborCandidate b, DateTime targetDate) {
    // 1. Balance (deudores primero)
    if (a.neighbor.balance != b.neighbor.balance) {
      return a.neighbor.balance.compareTo(b.neighbor.balance);
    }

    // 2. Tiempo desde última guardia (más descansado primero)
    final daysA = a.lastShiftDate != null ? targetDate.difference(a.lastShiftDate!).inDays : 9999;
    final daysB = b.lastShiftDate != null ? targetDate.difference(b.lastShiftDate!).inDays : 9999;

    if (daysA != daysB) {
      return daysB.compareTo(daysA); // Descendente
    }

    // 3. Alfabético
    return a.neighbor.fullName.compareTo(b.neighbor.fullName);
  }
}

class NeighborCandidate extends Equatable {
  final NeighborEntity neighbor;
  final DateTime? lastShiftDate;
  final OperationalProfile effectiveProfile;

  const NeighborCandidate({
    required this.neighbor,
    this.lastShiftDate,
    required this.effectiveProfile,
  });

  @override
  List<Object?> get props => [neighbor, lastShiftDate, effectiveProfile];
}

class ReplacementParams extends Equatable {
  final String shiftId;
  final String originalNeighborId;

  const ReplacementParams({required this.shiftId, required this.originalNeighborId});

  @override
  List<Object?> get props => [shiftId, originalNeighborId];
}
