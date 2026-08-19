#!/usr/bin/env node

// stop hook for end-of-turn Convex verification.
//
// Cursor's `stop` hook fires when the agent loop ends (status: completed |
// aborted | error) and cannot block completion, but it CAN return a
// `followup_message` that Cursor automatically submits as the next user
// message. See hooks.json `loop_limit`.
//
// Returns JSON only on stdout.

import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";
import {
  followup,
  getWorkspaceRoot,
  noop,
  pathExists,
  readHookInput,
} from "./hook-io.mjs";

const input = await readHookInput();
if (!input) {
  noop();
}

const status = typeof input.status === "string" ? input.status : "";
if (status !== "completed") {
  noop();
}

const loopCount =
  typeof input.loop_count === "number"
    ? input.loop_count
    : Number.parseInt(String(input.loop_count ?? "0"), 10);
if (Number.isFinite(loopCount) && loopCount >= 2) {
  noop();
}

const repoRoot = getWorkspaceRoot(input);
const convexDir = path.join(repoRoot, "convex");
if (!pathExists(convexDir)) {
  noop();
}

if (
  !pathExists(path.join(repoRoot, "tsconfig.json")) &&
  !pathExists(path.join(repoRoot, "package.json"))
) {
  noop();
}

function hasConvexDeployment() {
  if (process.env.CONVEX_DEPLOYMENT) {
    return true;
  }
  const envLocal = path.join(repoRoot, ".env.local");
  if (!pathExists(envLocal)) {
    return false;
  }
  return fs.readFileSync(envLocal, "utf8").includes("CONVEX_DEPLOYMENT");
}

function runCommand(command, args, options = {}) {
  return new Promise((resolve) => {
    const child = spawn(command, args, {
      cwd: repoRoot,
      shell: process.platform === "win32",
      stdio: ["ignore", "pipe", "pipe"],
      ...options,
    });

    let stdout = "";
    let stderr = "";
    child.stdout?.on("data", (chunk) => {
      stdout += chunk.toString();
    });
    child.stderr?.on("data", (chunk) => {
      stderr += chunk.toString();
    });
    child.on("close", (code) => {
      resolve({ code: code ?? 1, output: `${stdout}${stderr}` });
    });
    child.on("error", () => {
      resolve({ code: 1, output: "" });
    });
  });
}

async function maybeRunCodegen() {
  if (!hasConvexDeployment()) {
    return;
  }

  await Promise.race([
    runCommand("npx", ["--no-install", "convex", "codegen"], {
      stdio: ["ignore", "ignore", "ignore"],
    }),
    new Promise((resolve) => setTimeout(resolve, 25_000)),
  ]);
}

await maybeRunCodegen();

const tsc = await runCommand("npx", ["--no-install", "tsc", "--noEmit"]);
if (tsc.code === 0) {
  noop();
}

const output = tsc.output;
if (
  /could not determine executable to run|command not found/i.test(output)
) {
  noop();
}

const trimmed = output.slice(0, 1500);
followup(
  `The self-verify check found TypeScript errors after that turn ended. Run \`npx tsc --noEmit\`, fix every error below before considering the work done, then re-verify:\n\n${trimmed}`,
);
