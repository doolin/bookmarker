# ADR 0004: Platform Detection Strategy for Firefox Profiles

## Status

Accepted

## Context

Firefox stores profiles in different directories on each operating system.
We need to locate `places.sqlite` without asking the user to configure a
path (though we allow `--database` as an override).

The profile root directories are:

| Platform | Path |
|----------|------|
| macOS    | `~/Library/Application Support/Firefox/Profiles/` |
| Linux    | `~/.mozilla/firefox/` |
| Windows  | `%APPDATA%/Mozilla/Firefox/Profiles/` |

## Decision

`ProfileFinder` reads `RbConfig::CONFIG["host_os"]` at initialization and
maps it to a platform key ("darwin", "linux", "windows"). The constructor
accepts a `platform:` keyword for testing and cross-platform override.

When multiple profiles exist, `default_database` prefers the profile
directory containing "default-release" (Firefox's standard naming) and
falls back to the first alphabetically.

## Consequences

- **Positive:** Works on all three major platforms without user configuration.
- **Positive:** The `platform:` parameter makes all code paths testable on
  any development machine.
- **Negative:** The "prefer default-release" heuristic could pick the wrong
  profile if a user has customized their Firefox setup. The `--database` flag
  is the escape hatch.
- **Note:** The linux/windows/unknown branches in `detect_platform` are
  unreachable in the macOS test suite. This is expected and documented in the
  coverage report.
