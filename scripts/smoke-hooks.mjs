import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.join(scriptsDir, "..");

function runHook(scriptName, input) {
  return execSync(`node ${path.join(scriptsDir, scriptName)}`, {
    cwd: repoRoot,
    input: JSON.stringify(input),
    encoding: "utf8",
  }).trim();
}

const allowPayload = {
  command: "git status",
  workspace_roots: ["Z:/code/github.com/FoodTruckNerdz/ftn-site"],
};
assertJson(runHook("pre-commit-checks.mjs", allowPayload), {
  permission: "allow",
});

const commitAllowPayload = {
  command: "git commit -m test",
  workspace_roots: ["Z:/code/github.com/FoodTruckNerdz/ftn-site"],
};
assertJson(runHook("pre-commit-checks.mjs", commitAllowPayload), {
  permission: "allow",
});

const noConvexPayload = {
  command: "git commit -m test",
  workspace_roots: [path.join(repoRoot)],
};
assertJson(runHook("pre-commit-checks.mjs", noConvexPayload), {
  permission: "allow",
});

const tmp = fs.mkdtempSync(path.join(scriptsDir, "..", ".hook-smoke-"));
const convexDir = path.join(tmp, "convex");
fs.mkdirSync(convexDir);
fs.writeFileSync(
  path.join(convexDir, "bad.ts"),
  "export const x = query({ handler: async () => Date.now() });",
);
const denyPayload = {
  command: "git commit -m test",
  workspace_roots: [tmp],
};
const denied = JSON.parse(runHook("pre-commit-checks.mjs", denyPayload));
if (denied.permission !== "deny") {
  throw new Error(`expected deny, got ${JSON.stringify(denied)}`);
}
fs.rmSync(tmp, { recursive: true, force: true });

console.log("pre-commit hook smoke tests passed");

function assertJson(actualText, expected) {
  const actual = JSON.parse(actualText);
  for (const [key, value] of Object.entries(expected)) {
    if (actual[key] !== value) {
      throw new Error(
        `expected ${key}=${value}, got ${actual[key]} (${actualText})`,
      );
    }
  }
}
