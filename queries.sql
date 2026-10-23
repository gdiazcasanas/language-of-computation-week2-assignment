-- Everyday library queries. Run with:  sqlite3 library.db < queries.sql

.headers on
.mode column
PRAGMA foreign_keys = ON;

-- 1. Shelf: every book the library owns copies of, with its authors and
--    how many copies are available.
SELECT a.title,
       group_concat(trim(au.first_name || ' ' || au.last_name), ', ') AS authors,
       a.available_copies,
       a.total_copies
FROM book_availability a
JOIN book_authors ba ON ba.book_id = a.book_id
JOIN authors au      ON au.author_id = ba.author_id
WHERE a.total_copies > 0
GROUP BY a.book_id
ORDER BY a.title;

-- 2. Copies of "Dune" that are on the shelf right now.
SELECT c.copy_id, c.condition
FROM copies c
JOIN books b ON b.book_id = c.book_id
WHERE b.title = 'Dune'
  AND c.condition <> 'lost'
  AND NOT EXISTS (SELECT 1 FROM loans l
                  WHERE l.copy_id = c.copy_id AND l.returned_on IS NULL);

-- 3. What a member (Ana Rivera, member 1) currently has checked out.
SELECT b.title, l.copy_id, l.borrowed_on, l.due_on
FROM loans l
JOIN copies c ON c.copy_id = l.copy_id
JOIN books b  ON b.book_id = c.book_id
WHERE l.member_id = 1 AND l.returned_on IS NULL;

-- 4. Overdue loans, worst first.
SELECT * FROM overdue_loans ORDER BY days_overdue DESC;

-- 5. Most borrowed books of all time.
SELECT b.title, COUNT(*) AS times_borrowed
FROM loans l
JOIN copies c ON c.copy_id = l.copy_id
JOIN books b  ON b.book_id = c.book_id
GROUP BY b.book_id
ORDER BY times_borrowed DESC, b.title;

-- 6. Borrow: member 2 checks out copy 2 for 14 days.
--    Only inserts if the member is active and the copy is on the shelf.
INSERT INTO loans (copy_id, member_id)
SELECT 2, 2
WHERE EXISTS (SELECT 1 FROM members WHERE member_id = 2 AND status = 'active')
  AND EXISTS (SELECT 1 FROM copies  WHERE copy_id = 2 AND condition <> 'lost')
  AND NOT EXISTS (SELECT 1 FROM loans WHERE copy_id = 2 AND returned_on IS NULL);
SELECT changes() AS loans_created;

-- 7. Return: copy 2 comes back today.
UPDATE loans
SET returned_on = date('now')
WHERE copy_id = 2 AND returned_on IS NULL;
SELECT changes() AS loans_closed;
