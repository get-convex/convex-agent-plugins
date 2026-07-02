---
description: "Add Stripe billing/payments to the Convex app (checkout + webhook + gating)."
---

# Add billing / payments

Wire Stripe to Convex: a checkout action, an httpAction webhook that verifies the signature and updates subscription state, and gating by that state.

## Steps
1. Store the Stripe secret + webhook secret via the `env` micro power.
2. Create a checkout-session action.
3. Add an httpAction webhook in convex/http.ts that verifies the Stripe signature and writes subscription/customer state.
4. Gate features on the stored subscription state (server-side, never trust the client).

## Rules
- Verify the Stripe webhook signature in the httpAction — never trust unsigned events.
- Stripe keys live in Convex env (use the `env` micro power).
- Gate on server-stored subscription state, not client claims.
