
-- =====================================================
-- Exercise 1 — Create Comments Table
-- =====================================================

-- Scenario:
-- The task system needs a comments table.
-- Each comment belongs to one task and one user.

-- Questions:
-- 1. What relationships should Comment have?
-- Comment should be related to both Task and User, because each comment belongs to a specific task and a specific user.

-- 2. Should Task have a comments relationship?
-- Yes, a Task should be connected to comments so all comments for a task can be accessed easily.

-- 3. What should happen to comments when a task is deleted?
-- When a task is deleted, its comments should also be deleted to avoid orphan records.

CREATE TABLE comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);


-- =====================================================
-- Exercise 2 — Migration Creation
-- =====================================================

-- Questions:
-- 1. What does upgrade() do?
-- It applies the new database changes, such as creating the comments table.

-- 2. What does downgrade() do?
-- It reverses the migration and returns the database to the previous version.

-- 3. What happens if you downgrade this migration?
-- The comments table will be deleted, and all data stored in it will be lost.

-- SQL equivalent of upgrade:
CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- SQL equivalent of downgrade:
-- DROP TABLE comments;


-- =====================================================
-- Exercise 3 — CRUD Challenge
-- =====================================================

-- Scenario:
-- 1. Creates a team called "DevOps"
-- 2. Creates a user "diana_ops"
-- 3. Creates 3 tasks with different priorities
-- 4. Prints task count
-- 5. Closes one task
-- 6. Deletes the lowest priority task

-- Create team
INSERT INTO teams (name, description)
VALUES ('DevOps', 'Operations and Infrastructure team');

-- Create user
INSERT INTO users (username, email, full_name, team_id)
VALUES (
    'diana_ops',
    'diana.ops@example.com',
    'Diana Ops',
    (
        SELECT id
        FROM teams
        WHERE name = 'DevOps'
        LIMIT 1
    )
);

-- Create 3 tasks
INSERT INTO tasks (title, description, status, priority, assigned_to)
VALUES
(
    'Deploy on OCI',
    'Deploy the project on OCI',
    'open',
    1,
    (
        SELECT id
        FROM users
        WHERE username = 'diana_ops'
        LIMIT 1
    )
),
(
    'Do a migration',
    'Perform a database migration',
    'open',
    2,
    (
        SELECT id
        FROM users
        WHERE username = 'diana_ops'
        LIMIT 1
    )
),
(
    'Finish documentation',
    'Create diagrams of the infrastructure',
    'open',
    3,
    (
        SELECT id
        FROM users
        WHERE username = 'diana_ops'
        LIMIT 1
    )
);

-- Print task count
SELECT 
    u.full_name,
    COUNT(t.id) AS task_count
FROM users u
JOIN tasks t ON t.assigned_to = u.id
WHERE u.username = 'diana_ops'
GROUP BY u.full_name;

-- Close one task
UPDATE tasks
SET status = 'closed'
WHERE title = 'Deploy on OCI'
AND assigned_to = (
    SELECT id
    FROM users
    WHERE username = 'diana_ops'
    LIMIT 1
);

-- Delete the lowest priority task
DELETE FROM tasks
WHERE id = (
    SELECT id
    FROM tasks
    WHERE assigned_to = (
        SELECT id
        FROM users
        WHERE username = 'diana_ops'
        LIMIT 1
    )
    ORDER BY priority DESC
    LIMIT 1
);

-- Show remaining tasks
SELECT 
    t.title,
    t.status,
    t.priority
FROM tasks t
JOIN users u ON t.assigned_to = u.id
WHERE u.username = 'diana_ops';


-- =====================================================
-- Exercise 4 — Rollback Migration
-- =====================================================

-- Questions:
-- 1. What happens to the column?
-- The column or table created by the migration is removed because the rollback reverses the upgrade.

-- 2. What happens to the data?
-- The data inside the removed column or table is deleted as well.

-- Rollback:
DROP TABLE IF EXISTS comments;


-- =====================================================
-- Exercise 5 — Concept Check
-- =====================================================

-- 1. Why use ORM instead of raw SQL?
-- ORM allows developers to work with database data using objects instead of writing SQL manually.

-- 2. Why use migrations?
-- Migrations help control and track database structure changes over time.

-- 3. When would you rollback?
-- You rollback when a migration causes an error or when you need to undo a database change.

-- 4. Difference between add() and commit()?
-- add() prepares an object to be saved, while commit() permanently saves the change to the database.

-- 5. Why are relationships useful?
-- Relationships make it easier to connect and access related data, such as a user's tasks or a task's comments.