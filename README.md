# week2-assignment

This is my Module 2 assignment for MSAI-5523.

## Library database

A SQLite database for a lending library: books, authors, physical copies, members and loans.

- `schema.sql` creates the tables, constraints and views (`book_availability`, `overdue_loans`).
- `import_books.py` loads 10,000 books and their authors from the [goodbooks-10k](https://github.com/zygmuntz/goodbooks-10k) `books.csv`, cleaning up titles, years, ISBNs and author names on the way.
- `seed.sql` adds sample copies, members and loans for some of those books.
- `queries.sql` shows common tasks: listing what's on the shelf, checking availability, borrowing, returning and listing overdue loans.
- `erd.mmd` / `erd.png` show the entity-relationship diagram.

Build the database:

```bash
curl -fsSL -o books.csv https://raw.githubusercontent.com/zygmuntz/goodbooks-10k/master/books.csv
sqlite3 library.db < schema.sql
python3 import_books.py library.db books.csv
sqlite3 library.db < seed.sql
```

Run the example queries (they borrow and return a copy, so they change the data):

```bash
sqlite3 library.db < queries.sql
```
