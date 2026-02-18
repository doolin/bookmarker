# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-17

### Added

- Extract bookmarks from Firefox's `places.sqlite` database.
- Auto-detect Firefox profile directories on macOS, Linux, and Windows.
- Interactive terminal pager with 25-per-page default.
- Search bookmarks by title, URL, or folder name.
- Filter bookmarks by folder.
- List all bookmark folders.
- CLI with `--database`, `--search`, `--folder`, `--folders`, `--count`,
  `--per-page`, `--profiles`, `--version`, and `--help` flags.
- RSpec test suite with SimpleCov (98%+ line, 93%+ branch coverage).
