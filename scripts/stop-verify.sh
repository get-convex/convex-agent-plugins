#!/bin/bash
# Deprecated wrapper: hooks.json invokes stop-verify.mjs directly.
exec node "$(dirname "$0")/stop-verify.mjs"
