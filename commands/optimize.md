---
description: "Audit and optimize an existing Convex app: security, scale, upgrades, observability."
---

# Audit and optimize an existing Convex app

Run a read-first audit of the current Convex app and produce a concrete, prioritized plan. Default to plan, then confirm, then apply. Never change code without approval.

## Steps
1. Detect the app: a `convex/` directory, the schema, and whether it's an anonymous or cloud deployment.
2. Run the `convex-reviewer` pass (auth checks, args/returns validators, indexes-not-filter, OCC conflicts, pagination, schema design).
3. Run `check-updates` against the pinned `@convex-dev/*` components and flag breaking changes.
4. Offer to install `sentinel` for production error capture (its tables live in the user's own deployment).
5. Read recent production errors and logs via the Convex CLI (`convex data`, `logs`).
6. Present a prioritized plan — security and data-loss risks first, then scale, then observability — and apply only on explicit confirmation.

## Rules
- Read-only first. Present a plan and CONFIRM before changing any file.
- Compose, don't reinvent: use convex-reviewer, check-updates, and sentinel.
- Prioritize security and data-loss risks above style.
- Never auto-land changes on someone's existing prod app.
