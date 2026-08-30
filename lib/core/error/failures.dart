import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class RestPeriodViolationFailure extends Failure {
  final int minDaysRequired;
  final int actualDays;
  const RestPeriodViolationFailure({
    required this.minDaysRequired,
    required this.actualDays,
  }) : super('El vecino no cumple el periodo de descanso obligatorio ($actualDays/$minDaysRequired días).');

  @override
  List<Object?> get props => [message, minDaysRequired, actualDays];
}

class SecurityPolicyViolationFailure extends Failure {
  const SecurityPolicyViolationFailure(super.message);
}

class UnderQuotaNotAllowedFailure extends Failure {
  const UnderQuotaNotAllowedFailure()
      : super('La configuración actual no permite operar turnos con déficit de personal.');
}

class CandidateNotFoundFailure extends Failure {
  const CandidateNotFoundFailure()
      : super('No se encontraron candidatos elegibles que cumplan las restricciones de descanso y género.');
}
