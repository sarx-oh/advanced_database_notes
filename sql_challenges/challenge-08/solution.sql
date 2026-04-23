-- ============================================================
-- Exercise 1 — Find the slow query
-- ============================================================

EXPLAIN PLAN FOR
SELECT * 
FROM patient_visits 
WHERE site_id = 3;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) What scan type do you see? Why?
-- The execution plan shows a TABLE ACCESS FULL.
-- Oracle performs a full table scan because site_id has low cardinality,
-- meaning each value matches many rows. In that case, using an index may
-- not be efficient, so Oracle may prefer scanning the whole table.

-- b) site_id has values 1–5. Is this high or low cardinality?
-- Low cardinality.

-- c) Would adding an index on site_id help? Why or why not?
-- Probably not much. Since site_id has few distinct values, each value
-- returns a large percentage of rows, so Oracle may still prefer a full
-- table scan instead of using an index.



-- ============================================================
-- Exercise 2 — Create an index and see if it helps
-- ============================================================

-- Step 1: Create the index
CREATE INDEX idx_pv_visit_date
ON patient_visits (visit_date);

-- Step 2: Gather statistics
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3: Run the range query and check the plan
EXPLAIN PLAN FOR
SELECT * 
FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does Oracle use the index for this range?
-- Yes, Oracle can use the index for this date range query.

-- b) Change the range to the last 7 days. Does the plan change?
EXPLAIN PLAN FOR
SELECT * 
FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 7 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Answer:
-- The plan may stay the same, but Oracle is even more likely to benefit
-- from the index because fewer rows match the condition.

-- c) Change to the last 700 days. What happens?
EXPLAIN PLAN FOR
SELECT * 
FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 700 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Answer:
-- When the range becomes much larger, Oracle may decide not to use the index
-- and switch to a full table scan, because too many rows satisfy the condition.

-- d) Why does the range size affect whether Oracle uses the index?
-- Because the larger the range, the more rows Oracle needs to retrieve.
-- If too many rows match, using the index can become less efficient than
-- reading the entire table.



-- ============================================================
-- Exercise 3 — Composite index
-- ============================================================

CREATE INDEX idx_pv_patient_date 
ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

EXPLAIN PLAN FOR
SELECT * 
FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does the plan use the composite index?
-- Yes, Oracle should use the composite index idx_pv_patient_date because
-- the query filters by both patient_id and visit_date, matching the index definition.

-- b) Now try querying ONLY on visit_date (no patient_id).
EXPLAIN PLAN FOR
SELECT * 
FROM patient_visits
WHERE visit_date > SYSDATE - 90;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Answer:
-- Usually no. Oracle cannot efficiently use that composite index when only
-- visit_date is queried, because patient_id is the leading column.

-- c) What's the rule about column order in composite indexes?
-- In composite indexes, column order matters. Oracle can use the index
-- efficiently only if the query starts with the leftmost column(s).



-- ============================================================
-- Exercise 4 — Function that breaks an index
-- ============================================================

-- This query CAN use the index:
EXPLAIN PLAN FOR
SELECT * 
FROM patient_visits 
WHERE patient_id = 5432;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- This query usually cannot use the normal index:
EXPLAIN PLAN FOR
SELECT * 
FROM patient_visits 
WHERE TO_CHAR(patient_id) = '5432';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) What scan type did the second query use?
-- The second query uses a TABLE ACCESS FULL.

-- b) Why does wrapping a column in a function break index use?
-- Because the index is built on the original column values, not on the result
-- of the function. Oracle must evaluate TO_CHAR(patient_id) row by row,
-- which prevents normal index usage.

-- c) How would you rewrite the second query to allow index use?
-- Rewrite it without the function:
SELECT * 
FROM patient_visits 
WHERE patient_id = 5432;



-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
-- ============================================================

-- Scenario A
-- a) Would you add an index?
-- Yes.

-- b) On which column(s)?
-- On visit_date, or the main date column used in searches.

-- c) Any concerns?
-- The main concerns are extra overhead on inserts/updates and additional storage space.


-- Scenario B
-- a) Would you add an index?
-- Yes, but carefully.

-- b) On which column(s)?
-- On customer_id.
-- An index on order_status may not be very useful if it has low cardinality.

-- c) Any concerns?
-- A high insert rate makes indexes more expensive to maintain.
-- Too many indexes can improve reads but hurt write performance.


-- Scenario C
-- a) Would you add an index?
-- Yes.

-- b) On which column(s)?
-- On email.

-- c) What kind of index?
-- A UNIQUE index.

-- Example:
-- CREATE UNIQUE INDEX idx_customer_email ON customers(email);