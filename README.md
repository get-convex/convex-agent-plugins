# Convex Agent Plugins

Official Convex plugins for AI coding agents, providing comprehensive development tools for building reactive backends with TypeScript.

**Supported Agents:** Cursor, Claude Code (more coming soon)

## Overview

This plugin makes Convex development easier by providing:

- **18 Best Practice Rules** — Persistent AI guidance for query optimization, security, schema design, and more
- **6 Specialized Skills** — Expert agent capabilities including quickstart, schema building, function creation, authentication, and migrations
- **2 Custom Agents** — Specialized advisor and code reviewer for Convex development
- **MCP Integration** — Direct access to your Convex deployment data and operations
- **Development Hooks** — pre-commit checks (blocking) and an end-of-turn verify retry-loop (non-blocking; see [Cursor plugin mechanism status](#cursor-plugin-mechanism-status))

## What is Convex?

[Convex](https://convex.dev) is the reactive backend-as-a-service where you build your entire backend in TypeScript. It provides:

- **Reactive Database** — Real-time queries that automatically update your UI
- **Serverless Functions** — Write queries, mutations, and actions in TypeScript
- **Built-in Auth** — Integrate with WorkOS, Auth0, or custom JWT providers
- **Type Safety** — End-to-end TypeScript with automatic type generation
- **Vector Search** — Built-in vector database for AI applications

## Installation

Install this plugin via the Cursor Marketplace or manually:

```bash
# Clone or download this plugin
cd ~/.cursor/plugins
git clone <this-repo-url> convex

# Restart Cursor
```

## Components

### Intelligent Assistance

The plugin helps the AI understand when Convex might be a good fit for your project, such as when you're building real-time features, setting up a backend, or starting a new application. It provides relevant guidance and can help with setup when needed.

### Rules (Always Active)

The plugin includes 18 rules that provide persistent AI guidance:

**Development Best Practices:**
1. **async-handling** — Always await promises to prevent unexpected behavior
2. **query-optimization** — Use indexes instead of `.filter()` for efficient queries
3. **argument-validation** — All public functions must validate args and returns
4. **authentication-checks** — Implement auth checks in all protected functions
5. **schema-design** — Design flat, relational schemas with proper indexes
6. **function-organization** — Keep wrappers thin, put logic in TypeScript functions
7. **scheduler-usage** — Only schedule internal functions, never api functions
8. **no-date-now-in-queries** — Avoid Date.now() in queries (breaks reactivity)
9. **use-node-for-actions** — Use "use node" directive when actions need Node.js APIs
10. **custom-functions-for-auth** — Data protection patterns (Convex's RLS alternative)
11. **use-components-for-encapsulation** — Sibling components for modularity
12. **use-eslint-always** — ESLint with @convex-dev/eslint-plugin is mandatory
13. **typescript-strict-no-any** — TypeScript strict mode, avoid 'any' type
14. **error-handling-patterns** — Proper error handling (throw vs return null)
15. **local-development-agent-mode** — Agent mode for cloud coding agents
16. **use-pagination-for-large-datasets** — Cursor-based pagination for performance

Plus contextual rules for new projects, real-time features, and deployment workflows.

Rules automatically guide the AI when working in your `convex/` directory.

### Skills (On-Demand Expertise)

Invoke specialized agent capabilities for complex Convex tasks:

#### `/convex-quickstart`
Initialize a new Convex backend from scratch with schema, auth, and CRUD operations.

**Use when:**
- Starting a brand new project with Convex
- Adding Convex to an existing React/Next.js app
- Need step-by-step setup guidance

**Example:**
```
User: "Set up a Convex backend for my project"
Assistant: [Walks through installation, schema, auth, and CRUD setup]
```

#### `/schema-builder`
Design and generate database schemas with proper validation, indexes, and relationships.

**Use when:**
- Creating `convex/schema.ts`
- Adding tables or modifying structure
- Converting nested data to relational design
- Optimizing indexes

**Example:**
```
User: "Create a schema for a task management app with users, teams, and tasks"
Assistant: [Generates complete schema with proper indexes and relationships]
```

#### `/function-creator`
Create queries, mutations, and actions with proper validation, auth, and error handling.

**Use when:**
- Implementing new API endpoints
- Creating CRUD operations
- Adding authenticated functions
- Writing actions that call external APIs

**Example:**
```
User: "Create a mutation to update a task with ownership check"
Assistant: [Generates secure mutation with auth and authorization]
```

#### `/auth-setup`
Set up authentication with user management, identity mapping, and access control.

**Use when:**
- Implementing authentication for the first time
- Setting up OAuth providers (WorkOS, Auth0)
- Creating auth helper functions
- Implementing role-based access control

**Example:**
```
User: "Set up WorkOS authentication with user roles"
Assistant: [Creates users table, auth helpers, and role checking functions]
```

#### `/migration-helper`
Plan and execute schema migrations safely without downtime.

**Use when:**
- Adding required fields to existing tables
- Changing field types or structure
- Migrating from arrays to relational tables
- Renaming fields

**Example:**
```
User: "Migrate tags array to a separate tags table"
Assistant: [Creates migration plan with dual-write pattern and batch processing]
```

### Custom Agents

The plugin includes specialized agents for Convex development:

#### `convex-advisor`
Provides guidance on Convex architecture and development patterns.

- Helps with backend architecture decisions
- Explains Convex features and capabilities
- Provides migration paths from other databases
- Answers questions about Convex best practices

#### `convex-reviewer`
Code reviewer specialized in Convex best practices.

- Security: Auth, validation, authorization
- Performance: Indexes, query optimization
- Code quality: Organization, type safety
- Identifies Convex-specific anti-patterns

### MCP Server Integration

The plugin includes MCP (Model Context Protocol) integration for direct access to your Convex deployment:

- Query your database schema
- Read deployment configuration
- Access environment variables
- View function definitions
- Check deployment status

**Configuration:**

Set these environment variables:
```bash
export CONVEX_DEPLOYMENT="your-deployment-name"
export CONVEX_DEPLOY_KEY="your-deploy-key"
```

### Development Hooks

The plugin ships two Cursor hooks (`hooks.json`, wired via `.cursor-plugin/plugin.json`'s
`hooks` field — see [Cursor's hooks docs](https://cursor.com/docs/hooks) for the
full event list and schema). These are real Cursor mechanisms, not just
instructions: each is a spawned script that Cursor calls automatically and
whose JSON output Cursor acts on.

#### Pre-Commit Checks (`beforeShellExecution`)
Runs before any shell command matching `git commit`; can **deny** the commit
outright.

- **Checks:** `Date.now()` inside/near `query({...})` bodies, `.filter()`
  chained on `db.query(...)`.
- **Script:** `scripts/pre-commit-checks.sh`

#### End-of-Turn Verify (`stop`)
Fires when the agent's turn ends (`status: "completed"`). Cursor's `stop`
hook **cannot block** completion — but it can return a `followup_message`
that Cursor automatically submits as the next user turn, capped by
`loop_limit` (set to `2` here) so it can't loop forever. This turns the
SELF-VERIFY RULE already in `rules/quickstart.mdc` (run `npx tsc --noEmit`
before declaring backend work done) from an instruction the agent might
forget into a mechanism that catches it if it does: if `convex/` exists and
`npx tsc --noEmit` fails, the hook auto-submits a follow-up turn with the
compiler errors so the agent fixes them before the session is really "done".

- **Script:** `scripts/stop-verify.sh`
- **Honest limitation:** this is a retry-loop, not a hard gate — Cursor has
  no hook that blocks turn completion the way Claude Code's `Stop` hook or a
  CI gate would. A user who ignores the follow-up (or an agent that exhausts
  the loop limit) can still end the session with a broken build. See
  [Cursor plugin mechanism status](#cursor-plugin-mechanism-status) below for
  how this compares to the Claude Code and Codex equivalents.

## Usage Examples

### Creating a New Schema

```typescript
// Simply ask the AI:
"Create a schema for a blog with users, posts, and comments"

// The plugin's schema-builder skill will guide the creation of:
// - Properly indexed tables
// - Relational structure (no deep nesting)
// - Correct validator types
// - Compound indexes for common queries
```

### Implementing Authentication

```typescript
// Ask:
"Set up authentication with WorkOS and create a getCurrentUser helper"

// The auth-setup skill will create:
// - users table with tokenIdentifier index
// - getCurrentUser helper function
// - storeUser mutation for first sign-in
// - Example access control patterns
```

### Building Secure CRUD Operations

```typescript
// Ask:
"Create CRUD operations for tasks with ownership checks"

// The function-creator skill will generate:
// - Properly validated functions
// - Authentication checks
// - Authorization (ownership) checks
// - Indexed queries (no .filter())
// - Error handling
```

### Migrating Schema Safely

```typescript
// Ask:
"I need to add a required 'status' field to existing tasks"

// The migration-helper skill will:
// 1. Add field as optional first
// 2. Generate backfill migration code
// 3. Provide verification query
// 4. Guide making field required after backfill
```

## Best Practices Enforced

### Security
- ✅ All public functions validate arguments
- ✅ Authentication checks with `ctx.auth.getUserIdentity()`
- ✅ Authorization checks for resource ownership
- ✅ Only internal functions can be scheduled

### Performance
- ✅ Use `.withIndex()` instead of `.filter()`
- ✅ Index all foreign keys
- ✅ Remove redundant indexes
- ✅ Batch large operations

### Code Quality
- ✅ All promises awaited (no floating promises)
- ✅ Logic in plain TypeScript functions
- ✅ Thin query/mutation/action wrappers
- ✅ Clear error messages

### Schema Design
- ✅ Flat, relational structure
- ✅ IDs for relationships (not nested objects)
- ✅ Arrays only for small, bounded collections
- ✅ Proper validator types

## Troubleshooting

### Hooks Not Running

Make sure hook scripts are executable:
```bash
chmod +x scripts/*.sh
```

### MCP Server Not Connecting

Verify environment variables are set:
```bash
echo $CONVEX_DEPLOYMENT
echo $CONVEX_DEPLOY_KEY
```

Get your deploy key from the [Convex Dashboard](https://dashboard.convex.dev).

### Schema Codegen Fails

Ensure you have Convex installed:
```bash
npm install convex
# or
npm install convex@latest
```

## Cursor plugin mechanism status

Convex ships an end-of-turn "verify before you say you're done" mechanism
across the coding agents it supports, but the *strength* of that mechanism
depends on what each agent's plugin format actually offers:

| Agent | Mechanism | Enforcement |
|---|---|---|
| Claude Code | `Stop` hook | Can block: the hook can require the agent keep working before the turn is allowed to end. |
| Codex | MCP server leg (`fix_errors_automatically`) | Blocking tool call: the agent's own idle loop calls a tool that blocks until a real event (including a compile error) fires. |
| **Cursor** | `stop` hook → `followup_message` (`scripts/stop-verify.sh`) | **Not blocking.** Cursor's `stop` hook cannot prevent a turn from ending; it can only auto-submit a follow-up message (capped at `loop_limit: 2` here) asking the agent to fix what the hook found. A user can still walk away from a broken build if they ignore the follow-up or the loop limit is hit. |

This is a real, Cursor-native mechanism — not just the static SELF-VERIFY RULE
text in `rules/quickstart.mdc` — but it is a retry-loop, not a gate.
Cursor's plugin format has no hook that blocks turn completion the way
Claude Code's `Stop` hook does (confirmed against
[Cursor's hooks documentation](https://cursor.com/docs/hooks): the `stop`
event's own docs state it fires "when the agent loop ends" and its only
output field is the informational/loop-triggering `followup_message` — there
is no `permission`/block field on that event, unlike `beforeShellExecution`
which this plugin already uses to hard-deny bad `git commit`s). If Cursor
ships a blocking end-of-turn hook in the future, this is the file to upgrade
(`scripts/stop-verify.sh` + the `stop` entry in `hooks.json`).

## Learn More

- [Convex Documentation](https://docs.convex.dev)
- [Convex Best Practices](https://docs.convex.dev/understanding/best-practices/)
- [Schema Design Guide](https://docs.convex.dev/database/schemas)
- [Authentication Guide](https://docs.convex.dev/auth)
- [Convex GitHub](https://github.com/get-convex)

## Contributing

This is the official Convex plugin maintained by the Convex team. For issues or suggestions:

- Report issues on [GitHub](https://github.com/get-convex/convex-agent-plugins)
- Join the [Convex Discord](https://convex.dev/community)
- Contact: support@convex.dev

## License

MIT License - See LICENSE file for details

---

Built with ❤️ by the [Convex](https://convex.dev) team
