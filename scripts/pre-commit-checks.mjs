#!/usr/bin/env node

// beforeShellExecution hook for git commit checks.
// Returns JSON only on stdout.

import path from "node:path";
import {
  allow,
  deny,
  getWorkspaceRoot,
  pathExists,
  readHookInput,
} from "./hook-io.mjs";
import { scanConvexDirectory } from "./convex-scan.mjs";

const GIT_COMMIT_PATTERN = /(^|\s)git\s+commit(\s|$)/;

const input = await readHookInput();
if (!input) {
  allow();
}

const command = typeof input.command === "string" ? input.command : "";
if (!GIT_COMMIT_PATTERN.test(command)) {
  allow();
}

const repoRoot = getWorkspaceRoot(input);
if (!repoRoot) {
  allow();
}

const convexDir = path.join(repoRoot, "convex");
if (!pathExists(convexDir)) {
  allow();
}

const { dateNowInQueries, filterOnQueries } = scanConvexDirectory(convexDir);

if (dateNowInQueries.length > 0) {
  deny(
    "Commit blocked: found Date.now() inside/near Convex query functions.",
    "beforeShellExecution blocked this git commit because Date.now() was detected near query({}) in convex/. Queries should be deterministic for reactivity. Use server-generated timestamps in writes or pass time as an argument.",
  );
}

if (filterOnQueries.length > 0) {
  deny(
    "Commit blocked: found .filter() on Convex db.query() calls.",
    "beforeShellExecution blocked this git commit because .filter() was detected on db.query() in convex/. Prefer indexed access patterns such as .withIndex() for performance and correctness.",
  );
}

allow();
