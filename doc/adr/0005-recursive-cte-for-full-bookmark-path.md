# ADR 0005: Recursive CTE for Full Bookmark Path

## Status

Accepted (upcoming feature — see BACKLOG.md)

## Context

Firefox stores bookmarks in a self-referential tree via `moz_bookmarks`.
Each row has a `parent` column pointing to another row's `id`. The hierarchy
looks like:

```
root (id=1)
├── menu (id=2)
│   ├── Mozilla Firefox (id=7)
│   │   ├── Get Help
│   │   └── Customize Firefox
│   └── WebDev
│       └── Ruby
│           └── Some Bookmark     ← depth 4 from root
└── toolbar (id=3)
    └── Getting Started
```

The current implementation (`Database::QUERY`) joins only one level of
parent to get the immediate folder name. This loses the full path context
that users need to understand where a bookmark lives in their hierarchy.

Examining the real database shows a maximum nesting depth of 5 levels.

## Options Considered

### 1. Multiple LEFT JOINs (fixed depth)

```sql
LEFT JOIN moz_bookmarks p1 ON b.parent = p1.id
LEFT JOIN moz_bookmarks p2 ON p1.parent = p2.id
LEFT JOIN moz_bookmarks p3 ON p2.parent = p3.id
-- ...
```

- Simple to write for a known depth.
- Brittle: breaks silently if a user nests deeper than the hardcoded joins.
- Produces wide rows with many nullable columns.

### 2. Application-side traversal

Load all `moz_bookmarks` rows into a hash, walk the parent chain in Ruby.

- Flexible, handles any depth.
- Requires loading the entire bookmarks table (~500–2000 rows for folders)
  into memory, then iterating per bookmark.
- Two queries (or a query + post-processing step).

### 3. Recursive CTE (WITH RECURSIVE)

```sql
WITH RECURSIVE ancestry(bid, aid, path, d) AS (
  SELECT id, parent, '', 0
  FROM moz_bookmarks WHERE type = 1
  UNION ALL
  SELECT ancestry.bid, mb.parent,
    CASE WHEN ancestry.path = ''
         THEN COALESCE(mb.title, '')
         ELSE COALESCE(mb.title, '') || ' > ' || ancestry.path
    END,
    ancestry.d + 1
  FROM ancestry, moz_bookmarks mb
  WHERE mb.id = ancestry.aid AND mb.parent <> 0
)
SELECT ancestry.path, b.title, p.url
FROM ancestry
JOIN moz_bookmarks b ON ancestry.bid = b.id
JOIN moz_places p ON b.fk = p.id
WHERE p.url NOT LIKE 'place:%'
  AND ancestry.d = (
    SELECT MAX(a2.d) FROM ancestry a2 WHERE a2.bid = ancestry.bid
  )
ORDER BY ancestry.path;
```

- Handles arbitrary depth.
- Single query, all work done in SQLite.
- Produces paths like `menu > Bookmarks Toolbar > EstimationRestart`.
- Tested against the real database: works correctly at depth 5.

## Decision

Use a recursive CTE to build the full folder path for each bookmark.

The CTE starts at each type=1 bookmark and walks up the parent chain,
concatenating folder titles with ` > ` as a separator, until it reaches
the root node (parent = 0). The outermost query selects only the
maximum-depth row per bookmark, which contains the complete path.

This will replace the current single-join `QUERY` constant in
`Database`, and the `Bookmark` value object will gain a `path` field
(an array of folder names from root to parent) alongside the existing
`folder` field (which becomes the last element of `path`).

## Consequences

- **Positive:** Full path context in every bookmark, enabling tree display,
  hierarchical filtering, and meaningful export grouping.
- **Positive:** Single query — no application-side traversal needed.
- **Positive:** Handles any nesting depth without code changes.
- **Negative:** Recursive CTEs are harder to read and debug than flat joins.
  The query should be well-commented in source.
- **Negative:** Slight performance cost for the recursion. At 328 bookmarks
  and max depth 5, this is measured at under 50ms on the real database —
  negligible for a CLI tool.
- **Migration note:** The `folder` field on `Bookmark` will be preserved for
  backwards compatibility (as the immediate parent name). The new `path`
  field will contain the full chain. Display methods will be updated to show
  the full path when available.
