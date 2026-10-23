-- Library lending database schema (SQLite)
--
-- A book is a title (e.g. "Dune"). The library can own several physical
-- copies of the same book, and members borrow copies, not books.
--
-- Date columns are declared DATE. SQLite has no real date type and STRICT
-- tables only accept INTEGER/REAL/TEXT/BLOB/ANY, so tables with dates are
-- not STRICT. Dates are stored as 'YYYY-MM-DD' text, and a CHECK on each
-- one rejects anything that isn't a valid date in that format.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS overdue_loans;
DROP VIEW IF EXISTS book_availability;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS copies;
DROP TABLE IF EXISTS book_authors;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS members;

CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL
) STRICT;

CREATE TABLE books (
    book_id         INTEGER PRIMARY KEY,
    title           TEXT NOT NULL,
    isbn            TEXT UNIQUE,
    published_year  INTEGER,
    genre           TEXT
) STRICT;

-- A book can have several authors and an author can write several books.
CREATE TABLE book_authors (
    book_id    INTEGER NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    author_id  INTEGER NOT NULL REFERENCES authors(author_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, author_id)
) STRICT;

-- Physical copies on the shelf.
CREATE TABLE copies (
    copy_id      INTEGER PRIMARY KEY,
    book_id      INTEGER NOT NULL REFERENCES books(book_id),
    acquired_on  DATE NOT NULL DEFAULT (date('now'))
                 CHECK (date(acquired_on) IS acquired_on),
    condition    TEXT NOT NULL DEFAULT 'good'
                 CHECK (condition IN ('new', 'good', 'fair', 'poor', 'lost'))
);

CREATE TABLE members (
    member_id   INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    phone       TEXT,
    joined_on   DATE NOT NULL DEFAULT (date('now'))
                CHECK (date(joined_on) IS joined_on),
    status      TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'suspended'))
);

-- One row per borrowing. returned_on stays NULL until the copy comes back.
CREATE TABLE loans (
    loan_id      INTEGER PRIMARY KEY,
    copy_id      INTEGER NOT NULL REFERENCES copies(copy_id),
    member_id    INTEGER NOT NULL REFERENCES members(member_id),
    borrowed_on  DATE NOT NULL DEFAULT (date('now'))
                 CHECK (date(borrowed_on) IS borrowed_on),
    due_on       DATE NOT NULL DEFAULT (date('now', '+14 days'))
                 CHECK (date(due_on) IS due_on),
    returned_on  DATE
                 CHECK (returned_on IS NULL OR date(returned_on) IS returned_on),
    CHECK (due_on >= borrowed_on),
    CHECK (returned_on IS NULL OR returned_on >= borrowed_on)
);

-- A copy can only be out on one open loan at a time.
CREATE UNIQUE INDEX one_open_loan_per_copy
    ON loans(copy_id) WHERE returned_on IS NULL;

CREATE INDEX loans_member ON loans(member_id);
CREATE INDEX copies_book ON copies(book_id);
CREATE INDEX book_authors_author ON book_authors(author_id);

-- How many copies of each book exist and how many are on the shelf now.
CREATE VIEW book_availability AS
SELECT b.book_id,
       b.title,
       COUNT(c.copy_id) AS total_copies,
       COUNT(c.copy_id) - COUNT(l.loan_id) AS available_copies
FROM books b
LEFT JOIN copies c
       ON c.book_id = b.book_id AND c.condition <> 'lost'
LEFT JOIN loans l
       ON l.copy_id = c.copy_id AND l.returned_on IS NULL
GROUP BY b.book_id, b.title;

-- Loans not yet returned whose due date has passed.
CREATE VIEW overdue_loans AS
SELECT l.loan_id,
       m.first_name || ' ' || m.last_name AS member,
       m.email,
       b.title,
       l.copy_id,
       l.due_on,
       CAST(julianday('now') - julianday(l.due_on) AS INTEGER) AS days_overdue
FROM loans l
JOIN members m ON m.member_id = l.member_id
JOIN copies c  ON c.copy_id = l.copy_id
JOIN books b   ON b.book_id = c.book_id
WHERE l.returned_on IS NULL
  AND l.due_on < date('now');
