import assert from "node:assert/strict";
import test from "node:test";
import {
  hasDateNowNearQuery,
  hasFilterOnQuery,
  scanConvexDirectory,
} from "./convex-scan.mjs";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

test("hasDateNowNearQuery flags Date.now() within five lines of query({", () => {
  const content = [
    "export const list = query({",
    "  handler: async (ctx) => {",
    "    const now = Date.now();",
    "    return now;",
    "  },",
    "});",
  ].join("\n");
  assert.equal(hasDateNowNearQuery(content), true);
});

test("hasDateNowNearQuery ignores Date.now() far from query({", () => {
  const content = [
    "export const list = query({",
    "  handler: async (ctx) => ctx.db.query('items').collect(),",
    "});",
    "",
    "// unrelated",
    "",
    "",
    "",
    "",
    "export const other = mutation({",
    "  handler: async () => Date.now(),",
    "});",
  ].join("\n");
  assert.equal(hasDateNowNearQuery(content), false);
});

test("hasFilterOnQuery flags db.query().filter()", () => {
  const content =
    "return ctx.db.query('items').filter((q) => q.eq(q.field('x'), 1)).collect();";
  assert.equal(hasFilterOnQuery(content), true);
});

test("scanConvexDirectory walks nested convex files", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "convex-hook-test-"));
  const nested = path.join(root, "lib");
  fs.mkdirSync(nested, { recursive: true });
  fs.writeFileSync(
    path.join(nested, "bad.ts"),
    "export const x = query({ handler: async () => Date.now() });",
  );

  const result = scanConvexDirectory(root);
  assert.equal(result.dateNowInQueries.length, 1);
  assert.equal(result.filterOnQueries.length, 0);
  fs.rmSync(root, { recursive: true, force: true });
});
