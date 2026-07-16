#!/bin/bash

# beforeShellExecution hook for git commit checks (Cursor).
# Returns JSON only on stdout.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib-hook-checks.sh
source "${SCRIPT_DIR}/lib-hook-checks.sh"

allow() {
  printf '%s\n' '{"permission":"allow"}'
  exit 0
}

deny() {
  local user_message="$1"
  local agent_message="$2"
  printf '%s\n' "{\"permission\":\"deny\",\"user_message\":\"${user_message}\",\"agent_message\":\"${agent_message}\"}"
  exit 0
}

HOOK_INPUT="$(cat)"
if [ -z "$HOOK_INPUT" ]; then
  allow
fi

ONE_LINE_INPUT="${HOOK_INPUT//$'\n'/}"
ONE_LINE_INPUT="${ONE_LINE_INPUT//$'\r'/}"

COMMAND="$(json_get_string "$ONE_LINE_INPUT" "command" || true)"
HOOK_CWD="$(json_get_string "$ONE_LINE_INPUT" "cwd" || true)"
WORKSPACE_ROOT="$(json_get_first_array_string "$ONE_LINE_INPUT" "workspace_roots" || true)"
if [ -z "$HOOK_CWD" ]; then
  HOOK_CWD="$(pwd -P 2>/dev/null || pwd)"
fi

# Extra safety guard beyond matcher.
if [[ ! "$COMMAND" =~ (^|[[:space:]])git[[:space:]]+commit($|[[:space:]]) ]]; then
  allow
fi

REPO_ROOT="$WORKSPACE_ROOT"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$HOOK_CWD"
fi
if [ -z "$REPO_ROOT" ] && [ -d "${SCRIPT_DIR}/../.git" ]; then
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi
if [ -z "$REPO_ROOT" ]; then
  allow
fi

VIOLATION="$(convex_check_violation "${REPO_ROOT}/convex")"
case "$VIOLATION" in
  date_now)
    deny \
      "Commit blocked: found Date.now() inside/near Convex query functions." \
      "beforeShellExecution blocked this git commit because Date.now() was detected near query({}) in convex/. Queries should be deterministic for reactivity. Use server-generated timestamps in writes or pass time as an argument."
    ;;
  filter)
    deny \
      "Commit blocked: found .filter() on Convex db.query() calls." \
      "beforeShellExecution blocked this git commit because .filter() was detected on db.query() in convex/. Prefer indexed access patterns such as .withIndex() for performance and correctness."
    ;;
esac
allow
