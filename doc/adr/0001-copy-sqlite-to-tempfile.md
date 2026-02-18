# ADR 0001: Copy SQLite Database to Tempfile Before Reading

## Status

Accepted

## Context

Firefox holds a WAL (Write-Ahead Logging) lock on `places.sqlite` while
running. Attempting to open the file directly with SQLite from another process
can result in `SQLITE_BUSY` errors, partial reads, or — on some platforms —
database corruption if the reader and Firefox both write to the WAL index
simultaneously.

We considered three approaches:

1. **Open directly with `PRAGMA busy_timeout`** — reduces errors but doesn't
   eliminate them; still risks reading a mid-transaction snapshot.
2. **Use Firefox's JSON export** — requires the user to manually export
   bookmarks first; defeats the purpose of direct extraction.
3. **Copy the file to a tempfile, then read the copy** — one `FileUtils.cp`
   call gives us a consistent point-in-time snapshot with no lock contention.

## Decision

Copy `places.sqlite` to a `Tempfile` before opening it with SQLite3.
Delete the tempfile in an `ensure` block after reading.

## Consequences

- **Positive:** Zero lock contention with Firefox. Works whether Firefox is
  running or not. The copy is a consistent snapshot.
- **Positive:** The tempfile is cleaned up immediately; no disk accumulation.
- **Negative:** Doubles the momentary disk usage (~50–100 MB for a large
  places.sqlite). Acceptable for a CLI tool.
- **Negative:** The snapshot is stale by the time we read it. For a read-only
  bookmark browser this is not a concern.
