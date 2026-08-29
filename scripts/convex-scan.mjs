import fs from "node:fs";
import path from "node:path";

const SOURCE_EXTENSIONS = new Set([".ts", ".js"]);

export function listConvexSourceFiles(convexDir) {
  const files = [];

  function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(fullPath);
        continue;
      }
      if (SOURCE_EXTENSIONS.has(path.extname(entry.name))) {
        files.push(fullPath);
      }
    }
  }

  walk(convexDir);
  return files;
}

export function hasDateNowNearQuery(content) {
  const lines = content.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    if (!lines[i].includes("Date.now()")) {
      continue;
    }
    const start = Math.max(0, i - 5);
    for (let j = start; j <= i; j += 1) {
      if (lines[j].includes("query({")) {
        return true;
      }
    }
  }
  return false;
}

export function hasFilterOnQuery(content) {
  return /\.query\(.*\)\s*\.filter\(/m.test(content);
}

export function scanConvexDirectory(convexDir) {
  const dateNowInQueries = [];
  const filterOnQueries = [];

  for (const filePath of listConvexSourceFiles(convexDir)) {
    const content = fs.readFileSync(filePath, "utf8");
    if (hasDateNowNearQuery(content)) {
      dateNowInQueries.push(filePath);
    }
    if (hasFilterOnQuery(content)) {
      filterOnQueries.push(filePath);
    }
  }

  return { dateNowInQueries, filterOnQueries };
}
