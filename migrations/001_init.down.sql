
-- dbm:meta
-- irreversible: true
-- dbm:end

BEGIN;

-- =========================================================
-- DOWN MIGRATION
-- Eliminar las tablas creadas por la migración
-- =========================================================

-- 1. Eliminar la tabla que relaciona estudiantes
-- con sus paquetes actuales.
DROP TABLE IF EXISTS current_sets;

-- 2. Eliminar el registro de actividades.
DROP TABLE IF EXISTS activity_log;

-- 3. Eliminar los pagos.
DROP TABLE IF EXISTS payments;

-- 4. Eliminar los paquetes de clases.
DROP TABLE IF EXISTS class_sets;

-- 5. Eliminar los estudiantes.
DROP TABLE IF EXISTS students;

COMMIT;
