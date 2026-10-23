"""Load the goodbooks-10k catalog (books.csv) into the library database.

Fills books, authors and book_authors. Run it after schema.sql and before
seed.sql, which adds the sample copies, members and loans:

    sqlite3 library.db < schema.sql
    python3 import_books.py library.db books.csv
    sqlite3 library.db < seed.sql

Cleanup applied to the CSV:
- book_id is kept as is, so seed.sql can refer to books by their CSV id.
- Titles drop the trailing series note, e.g. "Twilight (Twilight, #1)" -> "Twilight".
- original_publication_year is stored as a whole number ("2008.0" -> 2008).
- isbn13 in the CSV is damaged (scientific notation, last digit lost), so the
  ISBN-13 is rebuilt from the 10-digit isbn after restoring its leading zeros.
  Books without a valid ISBN-10 get no ISBN.
- The authors field is split on commas into separate authors. Each name is
  split into first and last name on the last word, keeping particles such as
  "Le" or "van" with the last name. Single names like "Homer" have no first name.
- The CSV has no genre, so genre is left empty.
"""

import csv
import re
import sqlite3
import sys

SERIES_SUFFIX = re.compile(r"\s*\((?:[^()]|\([^()]*\))*#[^()]*\)\s*$")
NAME_PARTICLES = {"da", "de", "del", "della", "der", "di", "du", "la", "le", "van", "von"}


def clean_title(title):
    return SERIES_SUFFIX.sub("", title).strip()


def parse_year(value):
    return int(float(value)) if value.strip() else None


def isbn13_from_isbn10(isbn10):
    """Return the ISBN-13 for a (possibly zero-stripped) ISBN-10, or None if invalid."""
    isbn10 = isbn10.strip().upper().zfill(10)
    if not (isbn10[:9].isdigit() and (isbn10[9].isdigit() or isbn10[9] == "X")):
        return None
    total = sum((10 - i) * (10 if c == "X" else int(c)) for i, c in enumerate(isbn10))
    if total % 11 != 0:
        return None
    body = "978" + isbn10[:9]
    check = (10 - sum(int(d) * (1 if i % 2 == 0 else 3) for i, d in enumerate(body)) % 10) % 10
    return body + str(check)


def split_name(full_name):
    words = full_name.split()
    if len(words) == 1:
        return "", words[0]
    last_start = len(words) - 1
    while last_start > 1 and words[last_start - 1].lower() in NAME_PARTICLES:
        last_start -= 1
    return " ".join(words[:last_start]), " ".join(words[last_start:])


def main(db_path, csv_path):
    with open(csv_path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    books, book_authors = [], []
    author_ids = {}
    skipped_isbns = 0

    for row in rows:
        book_id = int(row["book_id"])
        isbn = isbn13_from_isbn10(row["isbn"]) if row["isbn"].strip() else None
        if row["isbn"].strip() and isbn is None:
            skipped_isbns += 1
        books.append((book_id, clean_title(row["title"]), isbn,
                      parse_year(row["original_publication_year"]), None))

        names = dict.fromkeys(n.strip() for n in row["authors"].split(",") if n.strip())
        for name in names:
            if name not in author_ids:
                author_ids[name] = len(author_ids) + 1
            book_authors.append((book_id, author_ids[name]))

    authors = [(author_id, *split_name(name)) for name, author_id in author_ids.items()]

    con = sqlite3.connect(db_path)
    con.execute("PRAGMA foreign_keys = ON")
    with con:
        con.execute("DELETE FROM book_authors")
        con.execute("DELETE FROM authors")
        con.execute("DELETE FROM books")
        con.executemany("INSERT INTO books (book_id, title, isbn, published_year, genre) "
                        "VALUES (?, ?, ?, ?, ?)", books)
        con.executemany("INSERT INTO authors (author_id, first_name, last_name) "
                        "VALUES (?, ?, ?)", authors)
        con.executemany("INSERT INTO book_authors (book_id, author_id) VALUES (?, ?)",
                        book_authors)
    con.close()

    print(f"Imported {len(books)} books, {len(authors)} authors, "
          f"{len(book_authors)} book-author links.")
    print(f"{sum(1 for b in books if b[2] is None)} books have no ISBN "
          f"({skipped_isbns} had an invalid ISBN-10 in the CSV).")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: python3 import_books.py <database> <books.csv>")
    main(sys.argv[1], sys.argv[2])
