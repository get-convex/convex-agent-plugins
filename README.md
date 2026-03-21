# Convex Agent Plugins

Official Convex plugins for AI coding agents, providing comprehensive development tools for building reactive backends with TypeScript.

**Supported Agents:** Cursor, Claude Code (more coming soon)

## Overview

This plugin makes Convex development easier by providing:

- **18 Best Practice Rules** — Persistent AI guidance for query optimization, security, schema design, and more
- **6 Specialized Skills** — Expert agent capabilities including quickstart, schema building, function creation, authentication, and migrations
- **2 Custom Agents** — Specialized advisor and code reviewer for Convex development
- **MCP Integration** — Direct access to your Convex deployment data and operations
- **Development Hooks** — Automated validation, codegen, and pre-commit checks

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
Initialize a new Convex backend from scratch or add Convex to an existing app. Supports multiple templates and Agent Mode for cloud environments.

#### `/convex-setup-auth`
Set up authentication with proper user management, identity mapping, and access control. Includes dedicated reference guides for **Convex Auth, Clerk, WorkOS, and Auth0**.

#### `/convex-create-component`
Design and build reusable Convex components with clear boundaries, isolated state, and app-facing wrappers. Supports local and packaged component patterns.

#### `/convex-migration-helper`
Plan and execute schema migrations safely using the `@convex-dev/migrations` component. Handles the **Widen -> Migrate -> Narrow** deployment workflow.

#### `/convex-performance-audit`
Audit and optimize application performance. Covers hot path reads, write contention (OCC), subscription costs, and function limits based on telemetry signals.


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

Automated checks and operations triggered by file changes:

#### Pre-Save Validation
Validates Convex functions have proper `args` and `returns` validators.

- **Triggers on:** Save in `convex/**/*.ts` or `convex/**/*.js`
- **Checks:** Function exports have args and returns defined

#### Post-Save Codegen
Automatically runs Convex codegen after schema changes.

- **Triggers on:** Save in `convex/schema.ts`
- **Action:** Runs `npx convex codegen --dev`

#### Pre-Commit Checks
Runs ESLint, type checking, and common issue detection before commits.

- **Checks:**
  - ESLint on Convex functions
  - TypeScript type checking
  - Date.now() in queries (warning)
  - .filter() on database queries (warning)

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
