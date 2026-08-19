import fs from "node:fs";

export async function readHookInput() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const text = Buffer.concat(chunks).toString("utf8").trim();
  if (!text) {
    return null;
  }
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

export function getWorkspaceRoot(input, hookCwd = process.cwd()) {
  const roots = input?.workspace_roots;
  if (Array.isArray(roots) && typeof roots[0] === "string" && roots[0]) {
    return roots[0];
  }
  if (typeof input?.cwd === "string" && input.cwd) {
    return input.cwd;
  }
  return hookCwd;
}

export function allow() {
  process.stdout.write('{"permission":"allow"}\n');
  process.exit(0);
}

export function deny(userMessage, agentMessage) {
  process.stdout.write(
    `${JSON.stringify({
      permission: "deny",
      user_message: userMessage,
      agent_message: agentMessage,
    })}\n`,
  );
  process.exit(0);
}

export function noop() {
  process.stdout.write("{}\n");
  process.exit(0);
}

export function followup(message) {
  process.stdout.write(`${JSON.stringify({ followup_message: message })}\n`);
  process.exit(0);
}

export function pathExists(path) {
  try {
    fs.accessSync(path);
    return true;
  } catch {
    return false;
  }
}
