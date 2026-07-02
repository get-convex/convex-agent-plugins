#!/bin/bash

# Self-contained smoke test for scripts/stop-verify.sh (the `stop` hook that
# implements the end-of-turn Convex verify mechanism for Cursor). No network
# access required beyond `npm install typescript` for the pass/fail fixtures.
#
# Usage: ./test-harness/test-stop-verify.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/scripts/stop-verify.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

check() {
  local name="$1"
  local expected_pattern="$2"
  local actual="$3"
  if printf '%s' "$actual" | grep -q -- "$expected_pattern"; then
    echo "ok   - $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL - $name"
    echo "       expected to match: $expected_pattern"
    echo "       got: $actual"
    FAIL=$((FAIL + 1))
  fi
}

run_hook() {
  local dir="$1"
  local status="$2"
  local loop_count="$3"
  (cd "$dir" && printf '{"status":"%s","loop_count":%s,"workspace_roots":["%s"]}' "$status" "$loop_count" "$dir" | bash "$HOOK")
}

echo "Testing $HOOK"
echo ""

# 1. No convex/ dir -> noop
mkdir -p "$TMP/noconvex"
OUT="$(run_hook "$TMP/noconvex" completed 0)"
check "no convex/ dir -> noop" '^{}$' "$OUT"

# 2. status != completed -> noop
mkdir -p "$TMP/aborted/convex"
OUT="$(run_hook "$TMP/aborted" aborted 0)"
check "status=aborted -> noop" '^{}$' "$OUT"

# 3. loop_count >= 2 -> noop
mkdir -p "$TMP/loopcap/convex"
OUT="$(run_hook "$TMP/loopcap" completed 2)"
check "loop_count>=2 -> noop" '^{}$' "$OUT"

# 4. no package.json/tsconfig -> noop
mkdir -p "$TMP/nopkg/convex"
OUT="$(run_hook "$TMP/nopkg" completed 0)"
check "no package.json/tsconfig -> noop" '^{}$' "$OUT"

# 5 & 6 need a real typescript install; skip gracefully if npm is unavailable
# or offline (this mirrors how the hook itself degrades: never crash, never
# false-positive on an environment problem).
if command -v npm >/dev/null 2>&1; then
  mkdir -p "$TMP/pass/convex" "$TMP/fail/convex"

  cat > "$TMP/pass/package.json" <<'EOF'
{"name":"pass-test","version":"1.0.0"}
EOF
  cat > "$TMP/pass/tsconfig.json" <<'EOF'
{"compilerOptions":{"strict":true,"noEmit":true}}
EOF
  echo 'export const x: number = 1;' > "$TMP/pass/convex/ok.ts"

  cat > "$TMP/fail/package.json" <<'EOF'
{"name":"fail-test","version":"1.0.0"}
EOF
  cat > "$TMP/fail/tsconfig.json" <<'EOF'
{"compilerOptions":{"strict":true,"noEmit":true}}
EOF
  echo 'export const x: number = "not a number";' > "$TMP/fail/convex/bad.ts"

  if (cd "$TMP/pass" && npm install --no-audit --no-fund typescript >/dev/null 2>&1) \
     && (cd "$TMP/fail" && npm install --no-audit --no-fund typescript >/dev/null 2>&1); then
    OUT="$(run_hook "$TMP/pass" completed 0)"
    check "passing tsc -> noop" '^{}$' "$OUT"

    OUT="$(run_hook "$TMP/fail" completed 0)"
    check "failing tsc -> followup_message" 'followup_message' "$OUT"
    check "failing tsc -> mentions the real error" 'not assignable' "$OUT"
  else
    echo "skip - typescript install failed (offline?) — skipping pass/fail tsc tests"
  fi
else
  echo "skip - npm not available — skipping pass/fail tsc tests"
fi

echo ""
echo "=========================="
echo "Passed: $PASS  Failed: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
