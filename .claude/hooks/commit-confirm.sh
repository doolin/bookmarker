#!/usr/bin/env bash
# commit-confirm.sh — tiered-consent commit gate (CSL-0020).
#
# Wired as a PreToolUse hook on the bare Bash matcher (no `if:` filter):
# the script itself decides whether the command is a git commit, via the
# shared matcher in git-commit-match.sh. Hardened 2026-08-29 after
# `git -C <path> commit` slipped past the original
# `if: Bash(git commit *)` prefix filter and landed unprompted
# (CSL-0051 finding): a consent gate must match the command's meaning,
# not its spelling.
#
# Emits permissionDecision "ask" for any git commit so the commit
# prompts regardless of allowlist entries. Edit / commit / push are
# three separate consent gates (AGENTS.md, Operating mode). Non-commit
# commands: silent exit 0 (no opinion).
#
# Adapted from dbb's commit-confirm.sh (Peter's reference
# implementation). dbb also wires this gate onto its committing wrapper
# scripts; clubstraylight has no such wrappers yet — extend the matcher
# when one appears.

set -u

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=git-commit-match.sh
. "$HOOK_DIR/git-commit-match.sh"

COMMAND=""
if [ ! -t 0 ]; then
  STDIN_JSON=$(cat || true)
  if [ -n "$STDIN_JSON" ] && command -v jq >/dev/null 2>&1; then
    COMMAND=$(printf '%s' "$STDIN_JSON" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
  fi
fi

if [ -z "$COMMAND" ] || ! is_git_commit "$COMMAND"; then
  exit 0
fi

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Tiered-consent commit gate: confirm intent to commit (edit/commit/push are separate gates)."}}
JSON
