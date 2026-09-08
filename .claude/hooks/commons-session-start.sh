#!/usr/bin/env bash
# commons-session-start.sh — Claude Code SessionStart hook for MIRROR
# repos (PRD-0003 §15, FR-H1). Canonical copy lives here in clubstraylight
# (the master repo does not wire this hook into itself — it has no mirror
# to check); mirror repos carry a synced copy in their own .claude/hooks/.
#
# FR-H1: at session open, surface commons-version skew — this repo's
# COMMONS.md mirror vs. the clubstraylight master. Compares the sibling
# checkout at ../clubstraylight.com (the layout every AGENTS.md already
# assumes for the knowledge graph pointer), skipping the 4-line
# provenance header bin/commons-sync prepends (the master carries no
# such header, so a raw byte compare would always read stale). Fails
# open: if the master isn't reachable at that path (different
# machine/layout), no skew banner — just the baseline message. No jq —
# portable.
#
# Dual-channel: systemMessage → operator (best-effort), and
# hookSpecificOutput.additionalContext → agent (reliable).

cat >/dev/null 2>&1   # drain the hook's JSON stdin

mirror="$CLAUDE_PROJECT_DIR/COMMONS.md"
master="$CLAUDE_PROJECT_DIR/../clubstraylight.com/COMMONS.md"

if [ -f "$master" ] && [ -f "$mirror" ] && ! diff -q <(tail -n +5 "$mirror") "$master" >/dev/null 2>&1; then
  message="Session started — commons mirror is STALE. Run commons-sync."
  context="Commons baseline: this repo's COMMONS.md differs from the clubstraylight master — your mirror is stale. Run 'ruby ~/src/clubstraylight.com/bin/commons-sync --repo \$CLAUDE_PROJECT_DIR' to update before treating any commons content as current. AGENTS.md overrides the commons only where its OVERRIDES section says so."
else
  message="Session started — commons baseline injected."
  context="Commons baseline: COMMONS.md at the repo root holds the read-only family conventions (synced from clubstraylight — never edit it here). Read it before convention-sensitive work unless already in context. AGENTS.md overrides it only where its OVERRIDES section says so."
fi

cat <<JSON
{
  "systemMessage": "$message",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$context"
  }
}
JSON
exit 0
