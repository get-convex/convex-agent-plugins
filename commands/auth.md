---
description: "Add authentication (passkeys/OAuth) to the current Convex app, including the auth.config.ts wiring."
---

# Add sign-in to the app

Install and wire @convex-dev/auth for the current app: a provider (passkeys by default, or OAuth/password), the server config, the client hooks, and a sign-in UI — correctly, including the auth.config.ts that's the #1 real-world auth footgun.

## Steps
1. Install @convex-dev/auth (pinned build) and add it to convex.config.ts.
2. Add the provider (Passkey by default; OAuth/password on request) in convex/auth.ts.
3. Write convex/auth.config.ts (the silently-always-signed-out bug lives here if it's wrong).
4. Wire the client: ConvexAuthProvider, the sign-in component, and route guards.
5. Verify a sign-in round-trips before declaring done.

## Rules
- Always write auth.config.ts — a missing/incorrect one makes the app silently always-signed-out with no error.
- Passkeys by default; only switch to password/OAuth on explicit request.
- Verify a real sign-in works before finishing.
