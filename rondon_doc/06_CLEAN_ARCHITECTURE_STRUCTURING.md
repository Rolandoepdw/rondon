---
tags:
  - architecture
  - clean-architecture
  - project-structure
created: 2026-08-29
---

# 06. Estructuración en Clean Architecture (Flutter)

## 1. Árbol de Directorios del Proyecto

El código fuente se organiza desacoplando las reglas de negocio de la infraestructura y la interfaz.

```text
lib/
├── core/                       # Núcleo compartido
│   ├── constants/              # Cadenas, claves de config
│   ├── error/                  # Failures (Domain) y Exceptions (Data)
│   └── services/               # Servicios de plataforma (Notifications, Launcher)
│
├── features/                   # Capas de funcionalidades
│   ├── neighbors/              # Vecinos y Cuadrillas
│   │   ├── data/               # SQLite Models, Datasources, Repos Implementation
│   │   ├── domain/             # Entities, Repos Contracts, Use Cases
│   │   └── presentation/       # Widgets, Cubits
│   │
│   ├── shifts/                 # Planificación y Replanificación
│   │   ├── data/
│   │   ├── domain/             # UseCases: GenerateCycle, ReplaceNeighbor, AuditShift
│   │   └── presentation/       # Calendar, ShiftDetail, ReplacementModal
│   │
│   └── messaging/              # Generación de mensajes WhatsApp
│
├── database/                   # Inicialización de Sqflite y Migraciones
└── main.dart                   # Punto de entrada e inyección de dependencias
```

---

## 2. Gestión de Errores de Dominio (Failures)

Se utilizan tipos de error específicos para las reglas de negocio, permitiendo una gestión de UI más granular.

```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class RestPeriodViolationFailure extends Failure {
  final int minDaysRequired;
  final int actualDays;
  const RestPeriodViolationFailure({
    required this.minDaysRequired,
    required this.actualDays,
  }) : super('El vecino no cumple el descanso obligatorio ($actualDays/$minDaysRequired días).');
}
```

---

## 3. Casos de Uso Críticos

### 3.1. `AuditShiftAttendanceUseCase`
Este caso de uso es vital para la integridad del sistema, ya que aplica los cambios de balance de forma atómica.

> [!CAUTION] Atomicidad
> Toda operación que modifique simultáneamente `ShiftAssignments`, `Neighbors` y `BalanceLedgerRecords` **DEBE** ejecutarse dentro de un bloque `db.transaction()`.

---

## 4. Directrices para el Desarrollo

1. **Inmutabilidad:** Entidades de dominio (`*Entity`) deben ser `const` y usar `copyWith`.
2. **Independencia:** La capa de Dominio no debe conocer a SQLite ni a Flutter.
3. **Mapeo:** Usar la capa de Data para transformar filas de DB en modelos y luego en entidades.

Ver también:
- [[01_SYSTEM_OVERVIEW_AND_DOMAIN_RULES|Reglas de Dominio]]
- [[02_DATA_MODEL_AND_SQLITE_SCHEMA|Esquema SQLite]]
- [[03_BUSINESS_LOGIC_AND_ALGORITHMS|Algoritmos de Negocio]]
