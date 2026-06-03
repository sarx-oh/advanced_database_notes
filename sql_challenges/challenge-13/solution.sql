/* ============================================================
   STEP 0 — CLEAN PREVIOUS OBJECTS
   ============================================================ */

BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_ticket_assignment_log';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily CASCADE CONSTRAINTS PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE dim_agent CASCADE CONSTRAINTS PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments CASCADE CONSTRAINTS PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE tickets CASCADE CONSTRAINTS PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/


/* ============================================================
   STEP 1 — SOURCE TABLES
   ============================================================ */

CREATE TABLE tickets (
    ticket_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR2(200) NOT NULL,
    status VARCHAR2(20) DEFAULT 'open' NOT NULL,
    priority VARCHAR2(10) DEFAULT 'medium' NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    resolved_at TIMESTAMP,
    assigned_to NUMBER,
    CONSTRAINT chk_ticket_status CHECK (
        status IN ('open', 'in_progress', 'blocked', 'resolved', 'closed')
    ),
    CONSTRAINT chk_ticket_priority CHECK (
        priority IN ('low', 'medium', 'high', 'critical')
    )
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER NOT NULL,
    assigned_to NUMBER NOT NULL,
    assigned_by NUMBER,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,
    CONSTRAINT fk_ticket_assignment_ticket
        FOREIGN KEY (ticket_id)
        REFERENCES tickets(ticket_id)
);

CREATE INDEX idx_ticket_assignment_lookup
ON ticket_assignments (
    ticket_id,
    valid_from,
    valid_to
);


/* ============================================================
   STEP 2 — SAMPLE DATA
   ============================================================ */

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'Login page bug',
    'resolved',
    'high',
    TIMESTAMP '2026-05-01 09:00:00',
    TIMESTAMP '2026-05-03 15:00:00',
    3
);

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'Database backup failure',
    'in_progress',
    'critical',
    TIMESTAMP '2026-05-02 10:00:00',
    NULL,
    2
);

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'UI alignment issue',
    'open',
    'low',
    TIMESTAMP '2026-05-03 11:00:00',
    NULL,
    4
);

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'API timeout errors',
    'blocked',
    'high',
    TIMESTAMP '2026-05-04 08:30:00',
    NULL,
    5
);

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'Email notification issue',
    'resolved',
    'medium',
    TIMESTAMP '2026-05-05 14:00:00',
    TIMESTAMP '2026-05-06 16:30:00',
    1
);


/* Ticket 1 is reassigned from agent 2 to agent 3 */

INSERT INTO ticket_assignments (
    ticket_id,
    assigned_to,
    assigned_by,
    valid_from,
    valid_to
) VALUES (
    1,
    2,
    1,
    TIMESTAMP '2026-05-01 09:00:00',
    TIMESTAMP '2026-05-02 12:00:00'
);

INSERT INTO ticket_assignments (
    ticket_id,
    assigned_to,
    assigned_by,
    valid_from,
    valid_to
) VALUES (
    1,
    3,
    2,
    TIMESTAMP '2026-05-02 12:00:00',
    NULL
);

INSERT INTO ticket_assignments (
    ticket_id,
    assigned_to,
    assigned_by,
    valid_from,
    valid_to
) VALUES (
    2,
    2,
    1,
    TIMESTAMP '2026-05-02 10:00:00',
    NULL
);

INSERT INTO ticket_assignments (
    ticket_id,
    assigned_to,
    assigned_by,
    valid_from,
    valid_to
) VALUES (
    3,
    4,
    2,
    TIMESTAMP '2026-05-03 11:00:00',
    NULL
);

INSERT INTO ticket_assignments (
    ticket_id,
    assigned_to,
    assigned_by,
    valid_from,
    valid_to
) VALUES (
    4,
    5,
    3,
    TIMESTAMP '2026-05-04 08:30:00',
    NULL
);

INSERT INTO ticket_assignments (
    ticket_id,
    assigned_to,
    assigned_by,
    valid_from,
    valid_to
) VALUES (
    5,
    1,
    4,
    TIMESTAMP '2026-05-05 14:00:00',
    NULL
);

COMMIT;


/* ============================================================
   STEP 3 — TRIGGER FOR ASSIGNMENT HISTORY
   ============================================================ */

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
AFTER INSERT OR UPDATE OF assigned_to ON tickets
FOR EACH ROW
BEGIN

    IF INSERTING THEN

        IF :NEW.assigned_to IS NOT NULL THEN
            INSERT INTO ticket_assignments (
                ticket_id,
                assigned_to,
                assigned_by,
                valid_from,
                valid_to
            )
            VALUES (
                :NEW.ticket_id,
                :NEW.assigned_to,
                NULL,
                SYSTIMESTAMP,
                NULL
            );
        END IF;

    ELSIF UPDATING THEN

        IF NVL(:OLD.assigned_to, -1) <> NVL(:NEW.assigned_to, -1) THEN

            UPDATE ticket_assignments
            SET valid_to = SYSTIMESTAMP
            WHERE ticket_id = :OLD.ticket_id
              AND valid_to IS NULL;

            IF :NEW.assigned_to IS NOT NULL THEN
                INSERT INTO ticket_assignments (
                    ticket_id,
                    assigned_to,
                    assigned_by,
                    valid_from,
                    valid_to
                )
                VALUES (
                    :NEW.ticket_id,
                    :NEW.assigned_to,
                    :OLD.assigned_to,
                    SYSTIMESTAMP,
                    NULL
                );
            END IF;

        END IF;

    END IF;

END;
/


/* ============================================================
   STEP 4 — TEST TRIGGER
   ============================================================ */

UPDATE tickets
SET assigned_to = 4
WHERE ticket_id = 2;

COMMIT;

SELECT
    assignment_id,
    ticket_id,
    assigned_to,
    assigned_by,
    valid_from,
    valid_to
FROM ticket_assignments
WHERE ticket_id = 2
ORDER BY valid_from;


/* ============================================================
   STEP 5 — DATA WAREHOUSE TABLES
   ============================================================ */

CREATE TABLE dim_agent (
    agent_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_agent_id NUMBER NOT NULL UNIQUE,
    agent_name VARCHAR2(100) NOT NULL,
    team VARCHAR2(50) NOT NULL
);

CREATE TABLE fact_ticket_daily (
    date_key NUMBER NOT NULL,
    agent_key NUMBER NOT NULL,
    status VARCHAR2(20) NOT NULL,
    priority VARCHAR2(10) NOT NULL,
    tickets_created NUMBER DEFAULT 0,
    tickets_resolved NUMBER DEFAULT 0,
    CONSTRAINT fk_fact_agent
        FOREIGN KEY (agent_key)
        REFERENCES dim_agent(agent_key)
);


/* ============================================================
   STEP 6 — POPULATE DIM_AGENT
   ============================================================ */

INSERT INTO dim_agent (
    source_agent_id,
    agent_name,
    team
) VALUES (
    1,
    'Monse',
    'Support'
);

INSERT INTO dim_agent (
    source_agent_id,
    agent_name,
    team
) VALUES (
    2,
    'Wynter',
    'Infrastructure'
);

INSERT INTO dim_agent (
    source_agent_id,
    agent_name,
    team
) VALUES (
    3,
    'Annette',
    'Frontend'
);

INSERT INTO dim_agent (
    source_agent_id,
    agent_name,
    team
) VALUES (
    4,
    'Sarah',
    'Backend'
);

INSERT INTO dim_agent (
    source_agent_id,
    agent_name,
    team
) VALUES (
    5,
    'Diego',
    'API Support'
);

COMMIT;


/* ============================================================
   STEP 7 — ETL IN SQL
   ============================================================ */

TRUNCATE TABLE fact_ticket_daily;

INSERT INTO fact_ticket_daily (
    date_key,
    agent_key,
    status,
    priority,
    tickets_created,
    tickets_resolved
)
SELECT
    date_key,
    agent_key,
    status,
    priority,
    SUM(tickets_created) AS tickets_created,
    SUM(tickets_resolved) AS tickets_resolved
FROM (
    SELECT
        TO_NUMBER(TO_CHAR(t.created_at, 'YYYYMMDD')) AS date_key,
        d.agent_key AS agent_key,
        t.status,
        t.priority,
        1 AS tickets_created,
        0 AS tickets_resolved
    FROM tickets t
    JOIN ticket_assignments ta
        ON t.ticket_id = ta.ticket_id
       AND ta.valid_from <= t.created_at
       AND (
            ta.valid_to IS NULL
            OR ta.valid_to > t.created_at
       )
    JOIN dim_agent d
        ON ta.assigned_to = d.source_agent_id

    UNION ALL

    SELECT
        TO_NUMBER(TO_CHAR(t.resolved_at, 'YYYYMMDD')) AS date_key,
        d.agent_key AS agent_key,
        t.status,
        t.priority,
        0 AS tickets_created,
        1 AS tickets_resolved
    FROM tickets t
    JOIN ticket_assignments ta
        ON t.ticket_id = ta.ticket_id
       AND ta.valid_from <= t.resolved_at
       AND (
            ta.valid_to IS NULL
            OR ta.valid_to > t.resolved_at
       )
    JOIN dim_agent d
        ON ta.assigned_to = d.source_agent_id
    WHERE t.resolved_at IS NOT NULL
)
GROUP BY
    date_key,
    agent_key,
    status,
    priority;

COMMIT;


/* ============================================================
   STEP 8 — FINAL VERIFICATION
   ============================================================ */

SELECT
    f.date_key,
    d.agent_name,
    d.team,
    f.status,
    f.priority,
    SUM(f.tickets_created) AS tickets_created,
    SUM(f.tickets_resolved) AS tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent d
    ON f.agent_key = d.agent_key
GROUP BY
    f.date_key,
    d.agent_name,
    d.team,
    f.status,
    f.priority
ORDER BY
    f.date_key,
    d.agent_name;