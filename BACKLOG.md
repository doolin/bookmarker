# Backlog

Planned features, improvements, and tech debt for the bookmarker gem.
Items are roughly prioritized within each section.

## Code Quality & Linting

- [x] Add RuboCop with a full `.rubocop.yml` — not ruby-standard, which is
  emasculated to resemble JavaScript linting and removes everything remotely
  challenging about code quality (complexity, line length, method length). We
  go full RuboCop.
- [ ] Add Reek for code smell detection
- [ ] Add Flog for complexity scoring (set a threshold, fail CI if exceeded)
- [ ] Add Flay for structural duplication detection
- [ ] Add Brakeman for security static analysis
- [x] Enforce frozen string literal and style consistency across all files
- [ ] Add `rake quality` task that runs all code quality tools in one pass

## CI/CD

- [ ] GitHub Actions workflow: run specs on Ruby 3.2, 3.3, 4.0
- [ ] CI step for RuboCop lint
- [ ] CI step for Reek, Flog, Flay, Brakeman
- [ ] CI step for SimpleCov minimum coverage gate (fail build if coverage drops)
- [ ] Automated gem build and publish to RubyGems on tagged release
- [ ] Dependabot or Renovate for dependency updates
- [ ] Add a Makefile or Taskfile for common developer workflows

## Features

### Full Bookmark Path

> **ADR:** [0005-recursive-cte-for-full-bookmark-path](doc/adr/0005-recursive-cte-for-full-bookmark-path.md)

Recursive CTE implemented — full folder hierarchy is resolved in a single
query, with path available as an array on each bookmark.

- [x] Walk the `moz_bookmarks` parent chain via recursive CTE to build full path
- [x] Add `Bookmark#path` returning the full folder hierarchy as an array
- [x] Display full path in terminal output (e.g. `[menu > WebDev > Ruby]`)
- [x] Support `--folder` filtering at any level of the path
- [ ] Add `--tree` flag to display bookmarks in a nested tree structure

### Export Formats

#### Architecture

- [ ] Add `Exporter` base class (`lib/bookmarker/exporter.rb`) with `#export`
      interface, injectable `bookmarks` and `output` stream, and a
      `.for(format, ...)` factory method that resolves format name to subclass
- [ ] Add `--export FORMAT` option to CLI; when present, skip pager and write
      serialized bookmarks to stdout via the matching exporter
- [ ] Add `--output FILE` option (only valid with `--export`); open file for
      writing and pass as the exporter's output stream
- [ ] Raise a clear error when `--output` is used without `--export`
- [ ] Revisit `--output FILE`, `--export FORMAT`, and `--no-color` interaction:
      file output should probably disable color automatically; `--export` to
      stdout may or may not want color (e.g. markdown vs json); decide whether
      `--no-color` is redundant when writing to a file or a non-TTY

#### Formats (in implementation order)

- [ ] `JsonExporter` — JSON array of bookmark objects (stdlib `json`, no deps)
- [ ] `CsvExporter` — CSV with columns: title, url, folder, path, date_added
      (stdlib `csv`)
- [ ] `MarkdownExporter` — Markdown list grouped by folder
- [ ] `HtmlExporter` — Netscape bookmark HTML format (DL/DT/DD nesting,
      compatible with browser import in Firefox/Chrome/Safari)
- [ ] `SqlExporter` — SQL INSERT statements; needs decisions on table schema,
      identifier quoting, and dialect (default to SQLite-compatible)

### Interactive Paging

Single-keystroke navigation implemented via `io/console`.

- [x] Raw terminal mode (single-keystroke navigation without Enter)
- [x] Use `io/console` for raw mode with graceful fallback to current line mode
- [ ] Arrow key support (up/down for prev/next page)
- [ ] `/` to enter search-within-results mode (like less)
- [ ] `o` to open the selected bookmark URL in the default browser
- [ ] Number keys to select a specific bookmark, not just page
- [ ] Probe terminal height via `IO#winsize` (or `io/console`) to compute
      page size automatically; fall back to `DEFAULT_PAGE_SIZE` when the probe
      fails (e.g. piped output, non-TTY, or `NoMethodError`)
- [ ] Resize-aware: detect terminal width/height and adjust page size
      dynamically on `SIGWINCH`

### Search & Filtering

- [ ] `--since DATE` / `--before DATE` — filter by date added
- [ ] `--sort title|date|url|folder` — configurable sort order
- [ ] Regex search with `--regex PATTERN`
- [ ] `--tags` support (Firefox tags are stored in `moz_bookmarks` type=2)
- [ ] Fuzzy search (Levenshtein or similar)
- [ ] `--duplicates` — find bookmarks with the same URL
- [ ] `--group-by domain` — cluster bookmarks by hostname instead of folder

### Data & Analysis

- [ ] `--stats` — summary dashboard: total bookmarks, bookmarks per folder,
      oldest/newest, most common domains, average folder depth
- [ ] `--dead-links` — HTTP HEAD check against each URL, report 404s and
      timeouts (useful for cleaning up stale bookmarks accumulated over years)
- [ ] `--validate` — check for orphan bookmarks (no parent), broken internal
      references, empty folders, or duplicate folder names at the same level

### Display

- [x] Colorized terminal output (title, URL, folder in different colors)
- [ ] `--format compact` — single-line per bookmark (title + truncated URL)
- [ ] `--format wide` — include date added and visit count
- [x] Respect `NO_COLOR` environment variable
- [ ] Configurable column widths based on terminal size

### Interactivity

- [ ] Bookmark preview — press `i` in the pager to show metadata (date added,
      visit count, full path) in a detail pane before returning to the list
- [ ] `--pick` — interactive multi-select mode (checkbox-style) that outputs
      selected bookmarks to stdout; composable with `--export` for piping a
      curated subset

### Multi-Profile

- [ ] `--diff PROFILE_A PROFILE_B` — show bookmarks unique to each profile,
      or common to both (useful for migrating or merging profiles)
- [ ] `--merge` — combine bookmarks from multiple profiles into a single
      deduplicated output

### Integration

- [ ] Shell completions — generate Bash/Zsh/Fish completions for flags and
      folder names; `--folder` could complete against actual folder names
      from the database
- [ ] `--pipe` — output bare URLs one per line, designed for piping into
      `xargs`, `curl`, `wget`, etc. (simpler than `--export json | jq`)
- [ ] RC file — `~/.bookmarkerrc` (YAML or TOML) for default database path,
      preferred export format, page size, color preferences

## Architecture & Tech Debt

- [ ] Extract an `Exporter` module with a strategy pattern for output formats
- [ ] Consider using `Ractor` or thread pool for parallel database reads (multi-profile)
- [ ] Add integration tests that run the real CLI binary (not just unit tests)
- [ ] Benchmark database read performance on large profiles (10k+ bookmarks)
- [ ] Support Chrome/Chromium bookmarks (JSON-based, different architecture)
- [ ] Support Safari bookmarks (plist-based)
- [ ] Add a `Bookmarker.configure` block for library-level defaults
- [ ] Ship a `man` page generated from the README or a ronn source file
- [ ] Structured logging — `--verbose` / `--debug` flag with leveled logging
      (profile discovery, DB copy timing, query duration) for troubleshooting
- [ ] `bookmarker init` — interactive first-run wizard that detects profiles,
      lets you pick a default, and writes `~/.bookmarkerrc`
- [ ] Snapshot history — save timestamped copies of `places.sqlite` so users
      can diff their bookmarks over time

## Web Application

A legitimate use case is embedding bookmarker in a personal server running
on localhost — a web UI for browsing, searching, and managing Firefox
bookmarks without the terminal. The core data layer (`Database`, `Bookmark`,
`ProfileFinder`) is already library-friendly; the gaps are around
serialization, pagination, and configuration.

- [ ] `Bookmark#as_json` — return a hash with `date_added` as ISO 8601 string,
      ready for `JSON.generate` or Rails `render json:`
- [ ] `Exporter#to_s` — convenience method that exports to a `StringIO` and
      returns the string; keeps `#export` for streaming, adds `#to_s` for
      request/response contexts
- [ ] `Database` query refinements — `#bookmarks(limit:, offset:)` for
      API-style pagination, `#bookmarks(sort:)` for sort order; push filtering
      into the SQL query layer instead of Ruby-side `#select`
- [ ] Facade module — `Bookmarker.bookmarks(database:, search:, folder:,
      limit:, offset:)` that wires up internals without requiring the caller
      to assemble `ProfileFinder` + `Database` + `Exporter` manually
- [ ] `Bookmarker.configure` block — set default database path, format
      preferences, and other library-level defaults (also useful for CLI)
- [ ] Thread safety audit — `@bookmarks ||=` memoization in `Database` is
      fine for single-threaded use but needs review for concurrent access
      under Puma or similar threaded servers
- [ ] Ensure `Color` module is never invoked from web code paths; consider
      making color a concern of terminal exporters only, not `Bookmark`

## Documentation

- [ ] Generate and host YARD docs (GitHub Pages or rubydoc.info)
- [ ] Add `CONTRIBUTING.md` with development setup instructions
- [ ] Add a `doc/adr/` entry for export format design decisions
- [ ] Add a `doc/adr/` entry for raw terminal mode trade-offs
- [ ] Add usage GIF/screenshot to README
