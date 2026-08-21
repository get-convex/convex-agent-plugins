---
description: "Build a durable multi-step retry pipeline on the Convex app with @convex-dev/workflow."
---

# Durable multi-step workflows → `@convex-dev/workflow`

When the task is "do step A, then B, then C, and retry each step independently if it fails" — a pipeline, ETL, or orchestration that must survive crashes — use the **workflow component**. Do NOT hand-roll it with a `jobs` table + chained `ctx.scheduler.runAfter` calls: that reinvents durability, loses per-step retry/backoff, and (measured) scores *worse* than a plain implementation. Copy this pattern.

## Wire the component

```ts
// convex/convex.config.ts
import { defineApp } from "convex/server";
import workflow from "@convex-dev/workflow/convex.config";
const app = defineApp();
app.use(workflow);
export default app;
```

## Define the workflow — one `step.run*` call per stage, retried independently

```ts
// convex/workflows.ts
import { WorkflowManager } from "@convex-dev/workflow";
import { components, internal } from "./_generated/api";
import { v } from "convex/values";

export const workflow = new WorkflowManager(components.workflow, {
  // Per-step default: retry each failed step independently with backoff.
  defaultRetryBehavior: { maxAttempts: 4, initialBackoffMs: 1000, base: 2 },
  retryActionsByDefault: true,
});

export const transcribeAndSummarize = workflow.define({
  args: { url: v.string(), userEmail: v.string() },
  handler: async (step, args): Promise<void> => {
    // Each step.runAction is durable + independently retried. If summarize fails
    // 3× then succeeds, transcribe is NOT re-run — completed steps are memoized.
    const transcript = await step.runAction(internal.youtube.transcribe, { url: args.url });
    const summary = await step.runAction(internal.llm.summarize, { transcript });
    await step.runAction(internal.email.sendSummary, { to: args.userEmail, summary });
  },
});
```

- **The handler's first arg is `step`, not `ctx`.** Call `step.runAction` / `step.runMutation` / `step.runQuery` with a codegen'd `internal.*` reference — never `ctx.run*` inside a workflow (that breaks durability/memoization).
- **Each `step.run*` is a durable checkpoint.** On crash or retry, completed steps are replayed from their stored result, not re-executed — so steps must target `internalAction`/`internalMutation`s that do the real work.
- **Override retry per step** when one stage is flakier: `step.runAction(ref, args, { retry: { maxAttempts: 6, initialBackoffMs: 500, base: 2 } })`. Set `{ retry: false }` for a step that must not repeat (already-idempotent external charge).
- The actual work (the YouTube fetch, the LLM call, the email send) lives in ordinary `internalAction`s — external APIs go in actions (see `convex-external-apis`), email via `@convex-dev/resend` (see `crons`).

## Start it (and optionally track status)

```ts
// from a public mutation/action the client calls:
const workflowId = await workflow.start(
  ctx,
  internal.workflows.transcribeAndSummarize,
  { url, userEmail },
);
// status later: await workflow.status(ctx, workflowId)  → cleanup: workflow.cleanup(ctx, workflowId)
```

## Don't
- ❌ A custom `jobs`/`pipeline` table + `ctx.scheduler.runAfter` chain to fake retries/ordering — that's what the component exists to replace.
- ❌ `ctx.runAction` inside the workflow handler — use `step.runAction` or you lose durability.
- ❌ Long synchronous work in one action to dodge steps — you lose independent retry and the 10-min action ceiling still applies per step.
