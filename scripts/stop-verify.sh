#!/bin/bash

# stop hook for end-of-turn Convex verification.
#
# Cursor's `stop` hook fires when the agent loop ends (status: completed |
# aborted | error) and cannot block completion, but it CAN return a
# `followup_message` that Cursor automatically submits as the next user
# message (docs: https://cursor.com/docs/hooks, section "stop" — "Can
# optionally auto-submit a follow-up user message to keep iterating.").
# That's the real enforcement lever available to a Cursor plugin: not a
# gate, but an automatic re-prompt loop, capped by `loop_limit` (see
# hooks.json) so it can't run forever.
#
# This mirrors the SELF-VERIFY RULE already shipped in rules/quickstart.mdc
# (run `npx tsc --noEmit` before declaring backend work done) but makes it a
# mechanism instead of an instruction: if the agent forgets/skips the rule,
# this hook catches it at turn-end and forces a follow-up turn with the
# actual compiler errors.
#
# Only acts on `status: "completed"` — an aborted/errored turn already has
# the user's attention, so we don't pile on. Only acts when a convex/
# directory exists in the workspace. Returns JSON only on stdout.

ltrim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  printf '%s' "$value"
}

json_parse_quoted_string() {
  local text="$1"
  local out=""
  local escaped=0
  local i
  local ch

  if [ "${text:0:1}" != '"' ]; then
    return 1
  fi
  text="${text:1}"

  for ((i = 0; i < ${#text}; i++)); do
    ch="${text:i:1}"
    if [ "$escaped" -eq 1 ]; then
      case "$ch" in
        \"|\\|/) out+="$ch" ;;
        b) out+=$'\b' ;;
        f) out+=$'\f' ;;
        n) out+=$'\n' ;;
        r) out+=$'\r' ;;
        t) out+=$'\t' ;;
        u)
          out+="\\u${text:i+1:4}"
          i=$((i + 4))
          ;;
        *) out+="$ch" ;;
      esac
      escaped=0
      continue
    fi

    case "$ch" in
      \\) escaped=1 ;;
      \")
        printf '%s' "$out"
        return 0
        ;;
      *) out+="$ch" ;;
    esac
  done

  return 1
}

json_get_string() {
  local json="$1"
  local key="$2"
  local rest

  rest="${json#*\"${key}\"}"
  if [ "$rest" = "$json" ]; then
    return 1
  fi
  rest="${rest#*:}"
  rest="$(ltrim "$rest")"
  json_parse_quoted_string "$rest"
}

json_get_first_array_string() {
  local json="$1"
  local key="$2"
  local rest

  rest="${json#*\"${key}\"}"
  if [ "$rest" = "$json" ]; then
    return 1
  fi
  rest="${rest#*:}"
  rest="$(ltrim "$rest")"
  if [ "${rest:0:1}" != "[" ]; then
    return 1
  fi
  rest="${rest:1}"
  rest="$(ltrim "$rest")"
  json_parse_quoted_string "$rest"
}

json_get_number() {
  local json="$1"
  local key="$2"
  local rest

  rest="${json#*\"${key}\"}"
  if [ "$rest" = "$json" ]; then
    return 1
  fi
  rest="${rest#*:}"
  rest="$(ltrim "$rest")"
  rest="${rest%%[,}]*}"
  printf '%s' "$(ltrim "$rest")"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

noop() {
  printf '%s\n' '{}'
  exit 0
}

followup() {
  local message
  message="$(json_escape "$1")"
  printf '%s\n' "{\"followup_message\":\"${message}\"}"
  exit 0
}

HOOK_INPUT="$(cat)"
if [ -z "$HOOK_INPUT" ]; then
  noop
fi

ONE_LINE_INPUT="${HOOK_INPUT//$'\n'/}"
ONE_LINE_INPUT="${ONE_LINE_INPUT//$'\r'/}"

STATUS="$(json_get_string "$ONE_LINE_INPUT" "status" || true)"
LOOP_COUNT="$(json_get_number "$ONE_LINE_INPUT" "loop_count" || true)"
WORKSPACE_ROOT="$(json_get_first_array_string "$ONE_LINE_INPUT" "workspace_roots" || true)"

# Only verify on a clean completion. An aborted/errored turn already has the
# user's attention; don't pile a second nag on top.
if [ "$STATUS" != "completed" ]; then
  noop
fi

# Self-limit independent of Cursor's own loop_limit: after 2 automatic
# follow-ups, stop nagging and let the user take the wheel. (loop_count
# starts at 0, so this allows follow-ups at loop_count 0 and 1.)
if [ -n "$LOOP_COUNT" ] && [ "$LOOP_COUNT" -ge 2 ] 2>/dev/null; then
  noop
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$WORKSPACE_ROOT"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(pwd -P 2>/dev/null || pwd)"
fi

CONVEX_DIR="${REPO_ROOT}/convex"
if [ ! -d "$CONVEX_DIR" ]; then
  noop
fi

if [ ! -f "${REPO_ROOT}/tsconfig.json" ] && [ ! -f "${REPO_ROOT}/package.json" ]; then
  noop
fi

if ! command -v npx >/dev/null 2>&1; then
  noop
fi

cd "$REPO_ROOT" || noop

# Refresh codegen before typechecking so the agent is never chased by stale convex/_generated/
# errors for functions it just wrote — the exact failure mode the "keep npx convex dev running"
# advice worked around, handled here so the user doesn't have to. ONLY when a deployment is
# already configured: like the Claude and Codex plugins, we do not provision or deploy an
# un-set-up project without the user's consent, so a cold project is left untouched (it just
# needs `convex dev` run once). Best-effort and watchdog-capped so it can never hang the turn;
# falls through to tsc unchanged on any failure.
if [ -d "${REPO_ROOT}/convex" ] && { grep -qs "CONVEX_DEPLOYMENT" "${REPO_ROOT}/.env.local" 2>/dev/null || [ -n "${CONVEX_DEPLOYMENT}" ]; }; then
  ( npx --no-install convex codegen >/dev/null 2>&1 ) &
  CODEGEN_PID=$!
  ( sleep 25; kill "$CODEGEN_PID" >/dev/null 2>&1 ) >/dev/null 2>&1 &
  WATCHDOG_PID=$!
  wait "$CODEGEN_PID" 2>/dev/null
  kill "$WATCHDOG_PID" >/dev/null 2>&1
fi

TSC_OUTPUT="$(npx --no-install tsc --noEmit 2>&1)"
TSC_STATUS=$?
if [ $TSC_STATUS -eq 0 ]; then
  noop
fi

# npx --no-install fails if tsc isn't already installed locally; don't nag
# about an environment problem that isn't a real type error.
if printf '%s' "$TSC_OUTPUT" | grep -qi "could not determine executable to run\|command not found"; then
  noop
fi

TRIMMED="$(printf '%s' "$TSC_OUTPUT" | head -c 1500)"
followup "The self-verify check found TypeScript errors after that turn ended. Run \`npx tsc --noEmit\`, fix every error below before considering the work done, then re-verify:

${TRIMMED}"
