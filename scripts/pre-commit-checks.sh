#!/bin/bash
# Deprecated wrapper: hooks.json invokes pre-commit-checks.mjs directly.
exec node "$(dirname "$0")/pre-commit-checks.mjs"
