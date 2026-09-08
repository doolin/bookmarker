#!/usr/bin/env bash
# git-commit-match.sh — shared matcher for the commit-gate hooks
# (CSL-0020, hardened 2026-08-29 after the CSL-0051 prefix-fragility
# finding: `git -C <path> commit` slipped past the original
# `if: Bash(git commit *)` prefix filter and landed unprompted).
# Sourced by commit-confirm.sh and the precommit checks, not executed.
#
# is_git_commit "<command>" returns 0 when the command is a git commit
# in any spelling: leading VAR=val assignments and git global options
# (-C <path>, -c <k=v>, --git-dir[=..], --work-tree[=..], ...) are
# skipped before the subcommand is tested. Chained commands (a && b)
# are out of scope — the shell discipline bans them, and a false
# negative here still lands on the permission prompt in Manual mode.

# git_commit_dir_arg "<command>" prints the first `-C <path>` value, or
# nothing when the commit targets the current directory. Lets repo-scoped
# checks (ticket prefix, ticket location) skip commits aimed at another
# repo, while the consent gate fires regardless of target.
git_commit_dir_arg() {
  local cmd="$1"
  set -f
  # shellcheck disable=SC2086
  set -- $cmd
  set +f
  while [ $# -gt 0 ] && printf '%s' "$1" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*='; do
    shift
  done
  [ "${1:-}" = "git" ] || return 0
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      -C) printf '%s' "${2:-}"; return 0 ;;
      commit) return 0 ;;
      -c|--git-dir|--work-tree|--namespace|--exec-path)
        [ $# -ge 2 ] || return 0
        shift 2
        ;;
      --git-dir=*|--work-tree=*|--namespace=*|--exec-path=*|-p|-P|--paginate|--no-pager|--bare|--no-optional-locks|--literal-pathspecs|--glob-pathspecs|--noglob-pathspecs|--icase-pathspecs)
        shift
        ;;
      *) return 0 ;;
    esac
  done
  return 0
}

is_git_commit() {
  local cmd="$1"
  set -f
  # shellcheck disable=SC2086
  set -- $cmd
  set +f
  # Skip leading environment assignments (FOO=1 git commit ...).
  while [ $# -gt 0 ] && printf '%s' "$1" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*='; do
    shift
  done
  [ "${1:-}" = "git" ] || return 1
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      commit) return 0 ;;
      -C|-c|--git-dir|--work-tree|--namespace|--exec-path)
        [ $# -ge 2 ] || return 1
        shift 2
        ;;
      --git-dir=*|--work-tree=*|--namespace=*|--exec-path=*|-p|-P|--paginate|--no-pager|--bare|--no-optional-locks|--literal-pathspecs|--glob-pathspecs|--noglob-pathspecs|--icase-pathspecs)
        shift
        ;;
      *) return 1 ;;
    esac
  done
  return 1
}
