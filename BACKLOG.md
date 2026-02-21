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

- [ ] `--export html` — Netscape bookmark HTML format (compatible with browser import)
- [ ] `--export markdown` — Markdown list grouped by folder
- [ ] `--export csv` — CSV with columns: title, url, folder, path, date_added
- [ ] `--export sql` — SQL INSERT statements for importing into another database
- [ ] `--export json` — JSON array of bookmark objects
- [ ] `--output FILE` — write export to a file instead of stdout
- [ ] Add an `Exporter` base class with format-specific subclasses

### Interactive Paging

Single-keystroke navigation implemented via `io/console`.

- [x] Raw terminal mode (single-keystroke navigation without Enter)
- [x] Use `io/console` for raw mode with graceful fallback to current line mode
- [ ] Arrow key support (up/down for prev/next page)
- [ ] `/` to enter search-within-results mode (like less)
- [ ] `o` to open the selected bookmark URL in the default browser
- [ ] Number keys to select a specific bookmark, not just page
- [ ] Resize-aware: detect terminal width/height and adjust page size

### Search & Filtering

- [ ] `--since DATE` / `--before DATE` — filter by date added
- [ ] `--sort title|date|url|folder` — configurable sort order
- [ ] Regex search with `--regex PATTERN`
- [ ] `--tags` support (Firefox tags are stored in `moz_bookmarks` type=2)
- [ ] Fuzzy search (Levenshtein or similar)
- [ ] `--duplicates` — find bookmarks with the same URL

### Display

- [x] Colorized terminal output (title, URL, folder in different colors)
- [ ] `--format compact` — single-line per bookmark (title + truncated URL)
- [ ] `--format wide` — include date added and visit count
- [x] Respect `NO_COLOR` environment variable
- [ ] Configurable column widths based on terminal size

## Architecture & Tech Debt

- [ ] Extract an `Exporter` module with a strategy pattern for output formats
- [ ] Consider using `Ractor` or thread pool for parallel database reads (multi-profile)
- [ ] Add integration tests that run the real CLI binary (not just unit tests)
- [ ] Benchmark database read performance on large profiles (10k+ bookmarks)
- [ ] Support Chrome/Chromium bookmarks (JSON-based, different architecture)
- [ ] Support Safari bookmarks (plist-based)
- [ ] Add a `Bookmarker.configure` block for library-level defaults
- [ ] Ship a `man` page generated from the README or a ronn source file

## Documentation

- [ ] Generate and host YARD docs (GitHub Pages or rubydoc.info)
- [ ] Add `CONTRIBUTING.md` with development setup instructions
- [ ] Add a `doc/adr/` entry for export format design decisions
- [ ] Add a `doc/adr/` entry for raw terminal mode trade-offs
- [ ] Add usage GIF/screenshot to README
