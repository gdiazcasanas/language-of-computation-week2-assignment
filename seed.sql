-- Sample lending data for the library database.
-- Load it after import_books.py: copies point at books by their
-- goodbooks-10k book_id. Members are made up. Loan dates are set around
-- October 2026.

PRAGMA foreign_keys = ON;

-- Book ids from books.csv:
--   126 Dune                          2555 Kindred
--   1574 The Left Hand of Darkness    2958 Gödel, Escher, Bach
--   354 Beloved                       94 One Hundred Years of Solitude
--   4047 Parable of the Sower
INSERT INTO copies (copy_id, book_id, acquired_on, condition) VALUES
    (1,  126,  '2024-01-10', 'good'),
    (2,  126,  '2024-01-10', 'fair'),
    (3,  126,  '2026-03-02', 'new'),
    (4,  2555, '2024-05-21', 'good'),
    (5,  1574, '2023-11-04', 'poor'),
    (6,  1574, '2025-02-14', 'good'),
    (7,  2958, '2022-08-30', 'fair'),
    (8,  354,  '2024-09-12', 'good'),
    (9,  94,   '2023-06-01', 'good'),
    (10, 94,   '2023-06-01', 'lost'),
    (11, 4047, '2026-01-20', 'new');

INSERT INTO members (member_id, first_name, last_name, email, phone, joined_on, status) VALUES
    (1, 'Ana',     'Rivera',  'ana.rivera@example.com',   '615-555-0101', '2024-02-01', 'active'),
    (2, 'Marcus',  'Lee',     'marcus.lee@example.com',   '615-555-0102', '2024-06-15', 'active'),
    (3, 'Priya',   'Shah',    'priya.shah@example.com',   NULL,           '2025-01-08', 'active'),
    (4, 'Daniel',  'Okafor',  'daniel.okafor@example.com','615-555-0104', '2025-09-30', 'suspended'),
    (5, 'Sofia',   'Novak',   'sofia.novak@example.com',  '615-555-0105', '2026-04-11', 'active');

INSERT INTO loans (loan_id, copy_id, member_id, borrowed_on, due_on, returned_on) VALUES
    -- Returned loans (history)
    (1,  1, 1, '2026-08-01', '2026-08-15', '2026-08-12'),
    (2,  4, 2, '2026-08-05', '2026-08-19', '2026-08-25'),
    (3,  7, 3, '2026-09-01', '2026-09-15', '2026-09-14'),
    (4,  1, 5, '2026-09-10', '2026-09-24', '2026-09-20'),
    -- Still out, due date not passed yet
    (5,  3, 1, '2026-10-15', '2026-10-29', NULL),
    (6,  8, 3, '2026-10-18', '2026-11-01', NULL),
    (7, 11, 5, '2026-10-20', '2026-11-03', NULL),
    -- Still out and overdue
    (8,  4, 2, '2026-09-25', '2026-10-09', NULL),
    (9,  6, 4, '2026-09-20', '2026-10-04', NULL);
