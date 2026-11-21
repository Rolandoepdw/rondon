import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rondon/core/utils/app_logger.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  static Future<Database>? _initFuture;

  AppDatabase._init();

  Future<Database> get database async {
    // 1. Return existing instance if already opened
    if (_database != null) return _database!;

    // 2. If initialization is already in progress, wait for it
    if (_initFuture != null) return _initFuture!;

    // 3. Otherwise, start initialization and store the future
    _initFuture = _initDB('rondon.db');
    
    try {
      _database = await _initFuture;
      return _database!;
    } finally {
      // Clear future once done (success or error)
      _initFuture = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      AppLogger.read('DATABASE', 'Connecting to database at: $path');

      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      AppLogger.error('DATABASE', 'Initialization failed', e);
      rethrow;
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.update('DATABASE', 'Upgrading version: $oldVersion -> $newVersion');

    if (oldVersion < 2) {
      AppLogger.update('DATABASE', 'Migrating schema to v2 (updating constraints to English values)');
      await db.execute('DROP TABLE IF EXISTS balance_ledger_records');
      await db.execute('DROP TABLE IF EXISTS shift_assignments');
      await db.execute('DROP TABLE IF EXISTS scheduled_shifts');
      await db.execute('DROP TABLE IF EXISTS neighbors');
      await db.execute('DROP TABLE IF EXISTS base_squads');
      await db.execute('DROP TABLE IF EXISTS shift_templates');
      await _createDB(db, newVersion);
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    AppLogger.info('DATABASE', 'Foreign keys constraint enabled');
  }

  Future _createDB(Database db, int version) async {
    AppLogger.create('DATABASE', 'Creating tables for version $version');
    try {
      // 1. Global System Configuration
      await db.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          description TEXT
        )
      ''');

      await db.execute('''
        INSERT INTO app_settings (key, value, description) VALUES
        ('min_days_between_shifts', '3', 'Días mínimos de descanso entre turnos para un mismo vecino'),
        ('allow_under_quota', '1', 'Permite cerrar guardias con déficit de personal (1=Sí, 0=No)'),
        ('notification_time_morning', '08:00', 'Horario de envío de recordatorio matutino (HH:mm)'),
        ('notification_time_evening', '20:00', 'Horario de envío de recordatorio nocturno (HH:mm)')
      ''');

      // 2. Shift Templates
      await db.execute('''
        CREATE TABLE shift_templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          allowed_gender TEXT NOT NULL CHECK (allowed_gender IN ('FEMALE_ONLY', 'MALE_ONLY', 'MIXED')),
          target_quota INTEGER NOT NULL CHECK (target_quota > 0),
          min_active_profiles INTEGER NOT NULL DEFAULT 1 CHECK (min_active_profiles >= 0),
          display_order INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
        )
      ''');

      // 3. Base Squads
      await db.execute('''
        CREATE TABLE base_squads (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          shift_template_id TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (shift_template_id) REFERENCES shift_templates(id) ON DELETE SET NULL
        )
      ''');

      // 4. Neighbors
      await db.execute('''
        CREATE TABLE neighbors (
          id TEXT PRIMARY KEY,
          full_name TEXT NOT NULL,
          phone TEXT,
          gender TEXT NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
          operational_profile TEXT NOT NULL CHECK (operational_profile IN ('ACTIVE', 'SUPPORT')),
          base_squad_id TEXT,
          balance INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          notes TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (base_squad_id) REFERENCES base_squads(id) ON DELETE SET NULL
        )
      ''');

      // 5. Scheduled Shifts
      await db.execute('''
        CREATE TABLE scheduled_shifts (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          shift_template_id TEXT NOT NULL,
          status TEXT NOT NULL CHECK (status IN ('PLANIFICADO', 'REPLANIFICADO', 'EN_CURSO', 'AUDITADO', 'DEFICIT_OPERATIVO')),
          notes TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (shift_template_id) REFERENCES shift_templates(id) ON DELETE RESTRICT
        )
      ''');

      // 6. Shift Assignments
      await db.execute('''
        CREATE TABLE shift_assignments (
          id TEXT PRIMARY KEY,
          scheduled_shift_id TEXT NOT NULL,
          neighbor_id TEXT NOT NULL,
          is_substitute INTEGER NOT NULL DEFAULT 0 CHECK (is_substitute IN (0, 1)),
          substitute_for_neighbor_id TEXT,
          attendance_status TEXT NOT NULL DEFAULT 'PENDIENTE' CHECK (attendance_status IN ('PENDIENTE', 'PRESENTE', 'FALTA')),
          effective_operational_profile TEXT NOT NULL CHECK (effective_operational_profile IN ('ACTIVE', 'SUPPORT')),
          balance_impacted INTEGER NOT NULL DEFAULT 0 CHECK (balance_impacted IN (0, 1)),
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (scheduled_shift_id) REFERENCES scheduled_shifts(id) ON DELETE CASCADE,
          FOREIGN KEY (neighbor_id) REFERENCES neighbors(id) ON DELETE RESTRICT,
          FOREIGN KEY (substitute_for_neighbor_id) REFERENCES neighbors(id) ON DELETE SET NULL,
          UNIQUE(scheduled_shift_id, neighbor_id),
          CHECK (
            (is_substitute = 0 AND substitute_for_neighbor_id IS NULL) OR
            (is_substitute = 1 AND substitute_for_neighbor_id IS NOT NULL)
          )
        )
      ''');

      // 7. Balance Ledger Records (Protected against CASCADE delete to preserve accounting history)
      await db.execute('''
        CREATE TABLE balance_ledger_records (
          id TEXT PRIMARY KEY,
          neighbor_id TEXT NOT NULL,
          scheduled_shift_id TEXT,
          delta INTEGER NOT NULL CHECK (delta != 0),
          reason TEXT NOT NULL CHECK (reason IN ('INASISTENCIA', 'COBERTURA_VOLUNTARIA', 'RECUPERACION_DEUDA', 'AJUSTE_MANUAL_ADMIN')),
          notes TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (neighbor_id) REFERENCES neighbors(id) ON DELETE RESTRICT,
          FOREIGN KEY (scheduled_shift_id) REFERENCES scheduled_shifts(id) ON DELETE SET NULL
        )
      ''');

      // Triggers to automatically synchronize neighbors.balance with balance_ledger_records
      await db.execute('''
        CREATE TRIGGER trg_ledger_ai AFTER INSERT ON balance_ledger_records BEGIN
          UPDATE neighbors SET balance = balance + NEW.delta WHERE id = NEW.neighbor_id;
        END;
      ''');

      await db.execute('''
        CREATE TRIGGER trg_ledger_ad AFTER DELETE ON balance_ledger_records BEGIN
          UPDATE neighbors SET balance = balance - OLD.delta WHERE id = OLD.neighbor_id;
        END;
      ''');

      await db.execute('''
        CREATE TRIGGER trg_ledger_au AFTER UPDATE ON balance_ledger_records BEGIN
          UPDATE neighbors SET balance = balance - OLD.delta + NEW.delta WHERE id = NEW.neighbor_id;
        END;
      ''');

      // Indexes
      await db.execute('CREATE INDEX idx_shifts_date ON scheduled_shifts(date)');
      await db.execute('CREATE INDEX idx_assignments_neighbor ON shift_assignments(neighbor_id)');
      await db.execute('CREATE INDEX idx_assignments_shift ON shift_assignments(scheduled_shift_id)');
      await db.execute('CREATE INDEX idx_assignments_neighbor_shift ON shift_assignments(neighbor_id, scheduled_shift_id)');
      await db.execute('CREATE INDEX idx_neighbors_balance ON neighbors(balance)');
      await db.execute('CREATE INDEX idx_neighbors_active ON neighbors(is_active)');
      
      AppLogger.create('DATABASE', 'Schema creation completed successfully');
    } catch (e) {
      AppLogger.error('DATABASE', 'Table creation failed', e);
      rethrow;
    }
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      AppLogger.info('DATABASE', 'Connection closed');
    }
  }
}
