# ADR 0002: Use Data.define for the Bookmark Value Object

## Status

Accepted

## Context

Bookmarks are read-only records extracted from SQLite. We need a lightweight
object with named fields, structural equality, and pattern matching support.

Options considered:

1. **Struct** — mutable by default, allows accidental field assignment.
2. **OpenStruct** — very slow, no type safety, deprecated in Ruby 3.4.
3. **Plain class with attr_reader** — boilerplate-heavy for a simple data carrier.
4. **Data.define** (Ruby 3.2+) — immutable by design, built-in equality,
   deconstruct_keys for pattern matching, minimal code.

## Decision

Use `Data.define(:id, :title, :url, :folder, :date_added)` with a block
to add `#to_s` and `#formatted` display methods.

## Consequences

- **Positive:** Immutable — no accidental mutation of bookmark records.
- **Positive:** Structural equality works out of the box for specs.
- **Positive:** Pattern matching with `in Bookmark[title:, url:]` is free.
- **Negative:** Requires Ruby >= 3.2. The gemspec already requires >= 3.1
  for other reasons; this nudges the effective minimum to 3.2.
