# ADR 0003: Injectable IO Streams for CLI and Pager

## Status

Accepted

## Context

The CLI and Pager classes write to stdout and read from stdin. Testing
interactive terminal behavior is notoriously difficult when classes are
hard-wired to global IO objects.

Options considered:

1. **Capture $stdout globally in tests** — fragile, breaks parallel test
   execution, and can mask output from test failures.
2. **Dependency-inject IO streams** — each class accepts `input:`, `output:`,
   `stderr:` as constructor or method parameters, defaulting to the real
   global streams.

## Decision

Both `CLI` and `Pager` accept IO streams as keyword arguments with
sensible defaults (`$stdin`, `$stdout`, `$stderr`). Tests pass `StringIO`
instances to capture and verify output without touching globals.

## Consequences

- **Positive:** Tests run fast, in isolation, with no global state mutation.
- **Positive:** The same API supports non-terminal use (piping, embedding).
- **Positive:** SimpleCov achieves high branch coverage because every code
  path is exercisable through injected IO.
- **Negative:** Slightly more ceremony in constructors. Worth it.
