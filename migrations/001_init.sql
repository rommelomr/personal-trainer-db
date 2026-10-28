-- dbm:meta
-- irreversible: false
-- dbm:end

-- Migración estructural: init
-- Escribe aquí el SQL de "up".
-- Si es reversible, crea también 001_init.down.sql
BEGIN;

-- =========================================================
-- 1. TABLA: students
-- =========================================================

CREATE TABLE students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    is_scholarship BOOLEAN NOT NULL DEFAULT FALSE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    status SMALLINT NOT NULL DEFAULT 1
);

-- =========================================================
-- 2. TABLA: class_sets
-- =========================================================

CREATE TABLE class_sets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,

    student_id BIGINT NOT NULL
        REFERENCES students(id)
        ON DELETE CASCADE,

    total_classes INTEGER NOT NULL
        CHECK (total_classes >= 0),

    used_classes INTEGER NOT NULL DEFAULT 0
        CHECK (used_classes >= 0),

    price NUMERIC(12, 2) NOT NULL
        CHECK (price >= 0),

    start_date TIMESTAMPTZ NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    status SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT chk_used_classes
        CHECK (used_classes <= total_classes),

    CONSTRAINT uq_class_sets_id_student
        UNIQUE (id, student_id)
);

CREATE INDEX idx_class_sets_student_id
    ON class_sets(student_id);


-- =========================================================
-- 4. TABLA: payments
-- =========================================================

CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,

    student_id BIGINT NOT NULL
        REFERENCES students(id)
        ON DELETE CASCADE,

    set_id BIGINT NOT NULL
        REFERENCES class_sets(id)
        ON DELETE RESTRICT,

    amount NUMERIC(12, 2) NOT NULL
        CHECK (amount >= 0),

    payment_date DATE NOT NULL,
    note TEXT NOT NULL DEFAULT '',

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    status SMALLINT NOT NULL DEFAULT 1
);

CREATE INDEX idx_payments_student_id
    ON payments(student_id);

CREATE INDEX idx_payments_set_id
    ON payments(set_id);

-- =========================================================
-- 5. TABLA: activity_log
-- =========================================================

CREATE TABLE activity_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,

    student_id BIGINT NOT NULL
        REFERENCES students(id)
        ON DELETE CASCADE,

    activity_date DATE NOT NULL,
    description TEXT NOT NULL,

    set_id BIGINT
        REFERENCES class_sets(id)
        NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    status SMALLINT NOT NULL DEFAULT 1
);

CREATE INDEX idx_activity_log_student_id
    ON activity_log(student_id);

-- =========================================================
-- 6. TABLA: current_sets
-- =========================================================

CREATE TABLE current_sets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,

    student_id BIGINT NOT NULL UNIQUE,
    set_id BIGINT NOT NULL UNIQUE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    status SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT fk_current_sets_student
        FOREIGN KEY (student_id)
        REFERENCES students(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_current_sets_class_set
        FOREIGN KEY (set_id, student_id)
        REFERENCES class_sets(id, student_id)
        ON DELETE CASCADE
);

-- =========================================================
-- 7. INSERTAR ESTUDIANTE
-- =========================================================

INSERT INTO students (
    uuid,
    full_name,
    created_at,
    is_scholarship
) VALUES (
    '4401d437-f175-4edd-924c-88badbf5ff7f',
    'Fernanda',
    '2026-10-07T22:44:45.315Z',
    FALSE
);

-- =========================================================
-- 8. INSERTAR PAQUETE DE CLASES
-- =========================================================

INSERT INTO class_sets (
    uuid,
    student_id,
    total_classes,
    used_classes,
    price,
    start_date
)
SELECT
    'e143b049-1f01-4f18-94a2-fac4dc659170',
    s.id,
    12,
    1,
    250000,
    '2026-10-07T22:44:45.315Z'
FROM students s
WHERE s.uuid = '4401d437-f175-4edd-924c-88badbf5ff7f';

-- =========================================================
-- 9. INSERTAR PAGO
-- =========================================================

INSERT INTO payments (
    uuid,
    student_id,
    set_id,
    amount,
    payment_date,
    note
)
SELECT
    'b3d53769-eb28-4bae-8b39-eec8f06fd6da',
    s.id,
    cs.id,
    100000,
    '2026-10-20',
    ''
FROM students s
JOIN class_sets cs
    ON cs.student_id = s.id
WHERE s.uuid = '4401d437-f175-4edd-924c-88badbf5ff7f'
  AND cs.uuid = 'e143b049-1f01-4f18-94a2-fac4dc659170';

-- =========================================================
-- 10. INSERTAR ACTIVIDAD INICIAL
-- =========================================================

INSERT INTO activity_log (
    uuid,
    student_id,
    activity_date,
    description,
    set_id
)
SELECT
    'd3ce515f-8cf0-4148-95aa-8fc9ce920a4b',
    s.id,
    '2026-10-07',
    'Inicio de clases',
    cs.id
FROM students s
JOIN class_sets cs
    ON cs.student_id = s.id
WHERE s.uuid = '4401d437-f175-4edd-924c-88badbf5ff7f'
  AND cs.uuid = 'e143b049-1f01-4f18-94a2-fac4dc659170';

-- =========================================================
-- 11. ASIGNAR PAQUETE ACTUAL
-- =========================================================

INSERT INTO current_sets (
    uuid,
    student_id,
    set_id
)
SELECT
    gen_random_uuid(),
    s.id,
    cs.id
FROM students s
JOIN class_sets cs
    ON cs.student_id = s.id
WHERE s.uuid = '4401d437-f175-4edd-924c-88badbf5ff7f'
  AND cs.uuid = 'e143b049-1f01-4f18-94a2-fac4dc659170';

-- =========================================================
-- 12. CONSULTA DE VERIFICACION
-- =========================================================

SELECT
    s.id AS student_id,
    s.uuid AS student_uuid,
    s.full_name AS estudiante,
    s.is_active AS estudiante_activo,
    s.status AS estado_estudiante,

    cs.id AS class_set_id,
    cs.uuid AS class_set_uuid,
    cs.total_classes AS clases_totales,
    cs.used_classes AS clases_utilizadas,
    cs.total_classes - cs.used_classes AS clases_disponibles,
    cs.price AS precio_paquete,

    COALESCE(SUM(p.amount), 0) AS total_pagado,
    cs.price - COALESCE(SUM(p.amount), 0) AS saldo_pendiente

FROM students s
JOIN current_sets cur
    ON cur.student_id = s.id
JOIN class_sets cs
    ON cs.id = cur.set_id
LEFT JOIN payments p
    ON p.student_id = s.id
    AND p.set_id = cs.id
    AND p.is_active = TRUE

WHERE s.uuid = '4401d437-f175-4edd-924c-88badbf5ff7f'

GROUP BY
    s.id,
    s.uuid,
    s.full_name,
    s.is_active,
    s.status,
    cs.id,
    cs.uuid,
    cs.total_classes,
    cs.used_classes,
    cs.price;

COMMIT;