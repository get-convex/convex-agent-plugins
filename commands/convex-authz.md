---
description: "Audit and harden Convex authorization: identity-from-arg impersonation, missing per-document ownership checks, PII-leaking public queries. Deterministic scan + canonical requireIdentity/requireOwner fix + tsc verify. Use for 'secure my app' / 'audit auth' / 'who can access this data', not generic code review."
---

# Convex Authz Auditor/Hardener

Audit and harden a Convex app's authorization against the single largest
real-defect cluster measured against generated Convex backends (44 of 214
confirmed defects): identity trusted from a client-supplied argument instead
of `ctx.auth`, missing per-document ownership checks, and public queries that
leak PII/financial data by a client-supplied id. SKIP if there's no `convex/`
directory.

## Steps

1. **Scan** every `convex/**/*.ts` (skip `_generated/` and `.d.ts`) for the 3
   shapes:
   - **Identity-from-arg**: a public `query(`/`mutation(` whose `args`
     declares `userId`/`actorId`/`ownerId`/`authorId`/`accountId` typed
     `v.id(...)`, with zero `ctx.auth` reference anywhere in the function
     block.
   - **Missing ownership check**: a handler that loads a doc via
     `ctx.db.get(args.xId)` and then patches/deletes/replaces it (or returns
     its fields) with no comparison against an authenticated identity.
   - **PII-leaking query**: a public query returning sensitive fields
     (email, revenue, audit logs, dashboards) parameterized by a
     client-supplied id with no `ctx.auth` gating.
   Report every hit with file:line before touching anything.
2. **Harden** each hit using the canonical pattern (do not invent a new one):
   ```ts
   // convex/model/auth.ts
   export async function requireIdentity(ctx) {
     const identity = await ctx.auth.getUserIdentity();
     if (!identity) throw new Error("401: not signed in");
     return identity;
   }
   export async function requireOwner(ctx, doc) {
     if (!doc) throw new Error("404: not found");
     const identity = await requireIdentity(ctx);
     if (doc.ownerId !== identity.subject) throw new Error("403: forbidden");
     return doc;
   }
   ```
   Replace client-supplied identity args with `requireIdentity(ctx)`; wrap
   every `_id`-keyed read/mutate with `requireOwner(ctx, await
   ctx.db.get(args.xId))`; scope PII-returning queries the same way. Leave
   genuinely internal/admin functions as `internalQuery`/`internalMutation`
   and unflagged.
3. **Verify** with `npx tsc --noEmit` (or the project's typecheck script),
   then re-run the scan to confirm 0 remaining hits.
4. Report findings grouped by shape, with file:line, why each is exploitable,
   and the concrete diff applied.

## Rules

- Identity always comes from `ctx.auth`, never a client-supplied argument
  (internal/admin functions are the one exception, and must stay internal).
- Every `_id`-keyed read/mutate needs a per-document ownership check, not
  just an identity check.
- Never leave a public query returning PII/financial data reachable by a
  client-supplied id with no auth gate.
- Reuse `requireIdentity`/`requireOwner` verbatim — don't fork a parallel
  helper.
- Always verify with tsc after hardening.
- This is a targeted authz pass, not a general review — hand
  performance/schema/validator findings to `convex-reviewer`.
- SKIP entirely when there is no `convex/` directory.
