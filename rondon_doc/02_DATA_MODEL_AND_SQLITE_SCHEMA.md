---
tags:
  - database
  - sqlite
  - dart-models
created: 2026-08-29
---

# 02. Modelo de Datos y Esquema SQLite

## 1. Esquema Relacional SQLite (DDL)

El diseño de la base de datos local prioriza la integridad referencial, el rastreo de auditoría para balances de puntos y la flexibilidad para agregar plantillas de turnos personalizadas.

```sql
-- Habilitar claves foráneas en SQLite
PRAGMA foreign_keys = ON;

-- 1. Configuración Global del Sistema
CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT
);

-- Valores predeterminados requeridos
INSERT INTO app_settings (key, value, description) VALUES
    ('min_days_between_shifts', '3', 'Días mínimos de descanso entre turnos para un mismo vecino'),
    ('allow_under_quota', '1', 'Permite cerrar guardias con déficit de personal (1=Sí, 0=No)'),
    ('notification_time_morning', '08:00', 'Horario de envío de recordatorio matutino (HH:mm)'),
    ('notification_time_evening', '20:00', 'Horario de envío de recordatorio nocturno (HH:mm)');

-- 2. Plantillas de Turnos (Configurables por Barrio)
CREATE TABLE shift_templates (
    id TEXT PRIMARY KEY, -- UUID v4
    name TEXT NOT NULL, -- Ej: "Turno Temprano", "Turno Madrugada"
    start_time TEXT NOT NULL, -- Formato "HH:mm" (ej. "22:00")
    end_time TEXT NOT NULL, -- Formato "HH:mm" (ej. "02:00")
    allowed_gender TEXT NOT NULL CHECK (allowed_gender IN ('SOLO_MUJERES', 'SOLO_HOMBRES', 'MIXTO')),
    target_quota INTEGER NOT NULL CHECK (target_quota > 0), -- Cupo requerido (ej. 3)
    min_active_profiles INTEGER NOT NULL DEFAULT 1 CHECK (min_active_profiles >= 0), -- Mínimo con perfil ACTIVO
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

-- 3. Cuadrillas Base (Afinidad / Grupos Habituales)
CREATE TABLE base_squads (
    id TEXT PRIMARY KEY, -- UUID v4
    name TEXT NOT NULL, -- Ej: "Cuadrilla Las Rosas", "Familia Pérez"
    shift_template_id TEXT, -- Plantilla preferente/habitual
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (shift_template_id) REFERENCES shift_templates(id) ON DELETE SET NULL
);

-- 4. Vecinos (Vecindario)
CREATE TABLE neighbors (
    id TEXT PRIMARY KEY, -- UUID v4
    full_name TEXT NOT NULL,
    phone TEXT, -- Para generación de enlaces wa.me
    gender TEXT NOT NULL CHECK (gender IN ('MASCULINO', 'FEMENINO')),
    operational_profile TEXT NOT NULL CHECK (operational_profile IN ('ACTIVO', 'APOYO')),
    base_squad_id TEXT,
    balance INTEGER NOT NULL DEFAULT 0, -- 0=Al día, +N=Crédito, -N=Deuda
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (base_squad_id) REFERENCES base_squads(id) ON DELETE SET NULL
);

-- 5. Turnos Programados (Instancias en Calendario)
CREATE TABLE scheduled_shifts (
    id TEXT PRIMARY KEY, -- UUID v4
    date TEXT NOT NULL, -- Formato ISO8601 "YYYY-MM-DD"
    shift_template_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PLANIFICADO', 'REPLANIFICADO', 'EN_CURSO', 'AUDITADO', 'DEFICIT_OPERATIVO')),
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (shift_template_id) REFERENCES shift_templates(id) ON DELETE RESTRICT
);

-- 6. Asignaciones de Guardia (Participantes por Turno)
CREATE TABLE shift_assignments (
    id TEXT PRIMARY KEY, -- UUID v4
    scheduled_shift_id TEXT NOT NULL,
    neighbor_id TEXT NOT NULL,
    is_substitute INTEGER NOT NULL DEFAULT 0 CHECK (is_substitute IN (0, 1)),
    substitute_for_neighbor_id TEXT, -- ID del vecino original ausente si aplica
    attendance_status TEXT NOT NULL DEFAULT 'PENDIENTE' CHECK (attendance_status IN ('PENDIENTE', 'PRESENTE', 'FALTA')),
    effective_operational_profile TEXT NOT NULL CHECK (effective_operational_profile IN ('ACTIVO', 'APOYO')),
    balance_impacted INTEGER NOT NULL DEFAULT 0 CHECK (balance_impacted IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (scheduled_shift_id) REFERENCES scheduled_shifts(id) ON DELETE CASCADE,
    FOREIGN KEY (neighbor_id) REFERENCES neighbors(id) ON DELETE RESTRICT,
    FOREIGN KEY (substitute_for_neighbor_id) REFERENCES neighbors(id) ON DELETE SET NULL,
    UNIQUE(scheduled_shift_id, neighbor_id) -- Un vecino no puede estar duplicado en el mismo turno
);

-- 7. Historial / Auditoría de Puntuación y Balances (Score Ledger)
CREATE TABLE balance_ledger_records (
    id TEXT PRIMARY KEY, -- UUID v4
    neighbor_id TEXT NOT NULL,
    scheduled_shift_id TEXT,
    delta INTEGER NOT NULL CHECK (delta IN (-1, 1)), -- Solo cambios discretos de +1 o -1
    reason TEXT NOT NULL CHECK (reason IN ('INASISTENCIA', 'COBERTURA_VOLUNTARIA', 'RECUPERACION_DEUDA', 'AJUSTE_MANUAL_ADMIN')),
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (neighbor_id) REFERENCES neighbors(id) ON DELETE CASCADE,
    FOREIGN KEY (scheduled_shift_id) REFERENCES scheduled_shifts(id) ON DELETE SET NULL
);

-- Índices de Rendimiento
CREATE INDEX idx_shifts_date ON scheduled_shifts(date);
CREATE INDEX idx_assignments_neighbor ON shift_assignments(neighbor_id);
CREATE INDEX idx_assignments_shift ON shift_assignments(scheduled_shift_id);
CREATE INDEX idx_neighbors_balance ON neighbors(balance);
CREATE INDEX idx_neighbors_active ON neighbors(is_active);
```

---

## 2. Definición de Enums de Dominio

```dart
enum Gender {
  masculino('MASCULINO'),
  femenino('FEMENINO');

  final String value;
  const Gender(this.value);

  static Gender fromString(String val) =>
      Gender.values.firstWhere((e) => e.value == val);
}

enum OperationalProfile {
  activo('ACTIVO'),
  apoyo('APOYO');

  final String value;
  const OperationalProfile(this.value);

  static OperationalProfile fromString(String val) =>
      OperationalProfile.values.firstWhere((e) => e.value == val);
}

enum AllowedGenderPolicy {
  soloMujeres('SOLO_MUJERES'),
  soloHombres('SOLO_HOMBRES'),
  mixto('MIXTO');

  final String value;
  const AllowedGenderPolicy(this.value);

  static AllowedGenderPolicy fromString(String val) =>
      AllowedGenderPolicy.values.firstWhere((e) => e.value == val);
}

enum ShiftStatus {
  planificado('PLANIFICADO'),
  replanificado('REPLANIFICADO'),
  enCurso('EN_CURSO'),
  auditado('AUDITADO'),
  deficitOperativo('DEFICIT_OPERATIVO');

  final String value;
  const ShiftStatus(this.value);

  static ShiftStatus fromString(String val) =>
      ShiftStatus.values.firstWhere((e) => e.value == val);
}

enum AttendanceStatus {
  pendiente('PENDIENTE'),
  presente('PRESENTE'),
  falta('FALTA');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String val) =>
      AttendanceStatus.values.firstWhere((e) => e.value == val);
}

enum LedgerReason {
  inasistencia('INASISTENCIA'),
  coberturaVoluntaria('COBERTURA_VOLUNTARIA'),
  recuperacionDeuda('RECUPERACION_DEUDA'),
  ajusteManualAdmin('AJUSTE_MANUAL_ADMIN');

  final String value;
  const LedgerReason(this.value);

  static LedgerReason fromString(String val) =>
      LedgerReason.values.firstWhere((e) => e.value == val);
}
```

---

## 3. Entidades de Dominio (Domain Layer)

### 3.1. NeighborEntity
```dart
class NeighborEntity {
  final String id;
  final String fullName;
  final String? phone;
  final Gender gender;
  final OperationalProfile operationalProfile;
  final String? baseSquadId;
  final int balance; // 0, +1, -1, etc.
  final bool isActive;
  final String? notes;

  const NeighborEntity({
    required this.id,
    required this.fullName,
    this.phone,
    required this.gender,
    required this.operationalProfile,
    this.baseSquadId,
    required this.balance,
    required this.isActive,
    this.notes,
  });

  bool get owesShifts => balance < 0;
  bool get hasCredits => balance > 0;
}
```

### 3.2. ShiftTemplateEntity
```dart
class ShiftTemplateEntity {
  final String id;
  final String name;
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final AllowedGenderPolicy allowedGender;
  final int targetQuota;
  final int minActiveProfiles;
  final int displayOrder;
  final bool isActive;

  const ShiftTemplateEntity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.allowedGender,
    required this.targetQuota,
    required this.minActiveProfiles,
    required this.displayOrder,
    required this.isActive,
  });
}
```

### 3.3. BaseSquadEntity
```dart
class BaseSquadEntity {
  final String id;
  final String name;
  final String? shiftTemplateId;
  final List<NeighborEntity> members;

  const BaseSquadEntity({
    required this.id,
    required this.name,
    this.shiftTemplateId,
    this.members = const [],
  });
}
```

### 3.4. ShiftAssignmentEntity
```dart
class ShiftAssignmentEntity {
  final String id;
  final String scheduledShiftId;
  final String neighborId;
  final NeighborEntity? neighbor; // Entidad embebida al cargar vistas agregadas
  final bool isSubstitute;
  final String? substituteForNeighborId;
  final AttendanceStatus attendanceStatus;
  final OperationalProfile effectiveOperationalProfile;
  final bool balanceImpacted;

  const ShiftAssignmentEntity({
    required this.id,
    required this.scheduledShiftId,
    required this.neighborId,
    this.neighbor,
    required this.isSubstitute,
    this.substituteForNeighborId,
    required this.attendanceStatus,
    required this.effectiveOperationalProfile,
    required this.balanceImpacted,
  });
}
```

### 3.5. ScheduledShiftEntity
```dart
class ScheduledShiftEntity {
  final String id;
  final DateTime date;
  final String shiftTemplateId;
  final ShiftTemplateEntity? template; // Entidad embebida
  final ShiftStatus status;
  final String? notes;
  final List<ShiftAssignmentEntity> assignments;

  const ScheduledShiftEntity({
    required this.id,
    required this.date,
    required this.shiftTemplateId,
    this.template,
    required this.status,
    this.notes,
    this.assignments = const [],
  });

  int get currentCount => assignments.length;
  
  int get activeProfilesCount => assignments
      .where((a) => a.effectiveOperationalProfile == OperationalProfile.activo)
      .length;

  bool get meetsSecurityRequirements =>
      template == null || activeProfilesCount >= template!.minActiveProfiles;

  bool get isUnderQuota =>
      template != null && assignments.length < template!.targetQuota;
}
```

### 3.6. BalanceLedgerRecordEntity
```dart
class BalanceLedgerRecordEntity {
  final String id;
  final String neighborId;
  final String? scheduledShiftId;
  final int delta; // +1 o -1
  final LedgerReason reason;
  final String? notes;
  final DateTime createdAt;

  const BalanceLedgerRecordEntity({
    required this.id,
    required this.neighborId,
    this.scheduledShiftId,
    required this.delta,
    required this.reason,
    this.notes,
    required this.createdAt,
  });
}
```

---

## 4. Estructura de Serialización (Data Layer Models)

Los modelos de la capa de datos (`Data Layer`) deben implementar los métodos estándar:
*   `Map<String, dynamic> toMap()`: Para inserciones/actualizaciones en SQLite.
*   `factory Model.fromMap(Map<String, dynamic> map)`: Para mapear filas de SQLite.
*   `Entity toEntity()`: Para transformar hacia la capa de Dominio puro.
*   `factory Model.fromEntity(Entity entity)`: Para encapsular entidades antes de persistir.

### Mapeo de Booleanos e Integers en SQLite
SQLite no cuenta con tipo booleano nativo. Se utiliza `INTEGER` con convención:
*   `0`: Falso (`false`).
*   `1`: Verdadero (`true`).

### Mapeo de Fechas
*   Campos de solo fecha (`ScheduledShift.date`): Cadena en formato ISO `YYYY-MM-DD` (ej. `2026-10-15`).
*   Marcas de tiempo (`created_at`): Cadena estándar UTC/Local `YYYY-MM-DD HH:mm:ss`.
