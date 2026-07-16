#!/bin/bash

# Shared JSON parsing helpers and Convex anti-pattern checks used by both the
# Cursor (pre-commit-checks.sh) and Claude Code (claude-pre-commit-checks.sh)
# git-commit hooks.

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
          # Keep unicode escapes as-is for safety.
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

# Checks a Convex functions directory for known anti-patterns.
# Prints "date_now", "filter", or nothing (via stdout) and always returns 0.
convex_check_violation() {
  local convex_dir="$1"

  if [ ! -d "$convex_dir" ]; then
    return 0
  fi

  # Block Date.now() in query functions.
  local date_now_in_queries
  date_now_in_queries="$(
    grep -r "Date\.now()" "$convex_dir"/ --include="*.ts" --include="*.js" \
      | grep -B 5 "query({" \
      | grep "Date\.now()" || true
  )"
  if [ -n "$date_now_in_queries" ]; then
    printf 'date_now'
    return 0
  fi

  # Block .filter() chained from Convex db.query().
  local filter_on_queries
  filter_on_queries="$(
    grep -r "\.query(.*)\s*\.filter(" "$convex_dir"/ --include="*.ts" --include="*.js" || true
  )"
  if [ -n "$filter_on_queries" ]; then
    printf 'filter'
    return 0
  fi

  return 0
}
