#!/bin/bash

# PreToolUse hook for git commit checks (Claude Code).
# Reads the Bash tool_input JSON on stdin and, for git commit commands,
# blocks via hookSpecificOutput if Convex anti-patterns are detected.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib-hook-checks.sh
source "${SCRIPT_DIR}/lib-hook-checks.sh"

HOOK_INPUT="$(cat)"
if [ -z "$HOOK_INPUT" ]; then
  exit 0
fi

ONE_LINE_INPUT="${HOOK_INPUT//$'\n'/}"
ONE_LINE_INPUT="${ONE_LINE_INPUT//$'\r'/}"

COMMAND="$(json_get_string "$ONE_LINE_INPUT" "command" || true)"
HOOK_CWD="$(json_get_string "$ONE_LINE_INPUT" "cwd" || true)"

# Extra safety guard beyond the hooks.json matcher/if.
if [[ ! "$COMMAND" =~ (^|[[:space:]])git[[:space:]]+commit($|[[:space:]]) ]]; then
  exit 0
fi

REPO_ROOT="$HOOK_CWD"
if [ -z "$REPO_ROOT" ] && [ -d "${SCRIPT_DIR}/../.git" ]; then
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi
if [ -z "$REPO_ROOT" ]; then
  exit 0
fi

VIOLATION="$(convex_check_violation "${REPO_ROOT}/convex")"

REASON=""
case "$VIOLATION" in
  date_now)
    REASON="Commit blocked: Date.now() detected near query({}) in convex/. Queries should be deterministic for reactivity. Use server-generated timestamps in writes or pass time as an argument."
    ;;
  filter)
    REASON="Commit blocked: .filter() detected on db.query() in convex/. Prefer indexed access patterns such as .withIndex() for performance and correctness."
    ;;
  *)
    exit 0
    ;;
esac

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$REASON"
exit 0
