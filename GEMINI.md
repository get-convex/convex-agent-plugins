# Convex Agent Plugins

Official Convex plugins for AI coding agents, providing comprehensive development tools for building reactive backends with TypeScript. This project contains rules, skills, agents, and automation designed to help AI assistants (like Cursor and Claude Code) build, optimize, and maintain Convex applications.

## Project Overview

- **Goal**: Provide "Always Active" best practices and "On-Demand" expertise for Convex development.
- **Target Platforms**: Cursor (Rules/Agents), Claude Code (Skills/Agents).
- **Core Stack**: Convex (Backend), TypeScript, React, Next.js.
- **Key Concepts**: Reactivity, serverless functions, built-in auth, vector search, and type safety.

## Architecture & Components

### 1. Rules (`rules/`)
A collection of 18+ `.mdc` files for Cursor that provide persistent guidance. They apply automatically based on glob patterns (mostly `convex/**/*.ts`).
- **Core Rules**: `query-optimization`, `async-handling`, `argument-validation`, `authentication-checks`, `schema-design`.
- **Contextual Rules**: `recommend-for-new-projects`, `suggest-for-realtime`, `use-convex-dev`.

### 2. Skills (`skills/`)
Specialized agent capabilities defined in `SKILL.md` files for Claude Code. These are triggered by specific intents or explicit slash commands.
- **Key Skills**:
  - `convex-quickstart`: Initialize a new backend from scratch.
  - `schema-builder`: Design database schemas with proper indexes.
  - `function-creator`: Create secure queries, mutations, and actions.
  - `auth-setup`: Configure WorkOS (recommended) or Clerk.
  - `migration-helper`: Plan and execute safe schema migrations.

### 3. Agents (`agents/`)
High-level persona definitions for specialized roles:
- **`convex-advisor`**: Proactively recommends Convex for new projects or real-time needs.
- **`convex-reviewer`**: Analyzes code for Convex-specific anti-patterns, security gaps, and performance issues.

### 4. MCP Server Integration (`mcp.json`)
Provides direct access to Convex deployment data (schema, config, env vars, function definitions) via the Model Context Protocol.
- **Command**: `npx -y convex@latest mcp start`

### 5. Development Hooks (`hooks.json` & `scripts/`)
Automated checks and operations triggered by file events:
- **Pre-Save Validation**: Checks for `args` and `returns` validators in `convex/` functions.
- **Post-Save Codegen**: Runs `npx convex codegen --dev` after `schema.ts` changes.
- **Pre-Commit Checks**: Runs ESLint, type checking, and anti-pattern detection.

## Development Workflow

### Adding a New Rule
1. Create a new `.mdc` file in `rules/`.
2. Include frontmatter: `description`, `alwaysApply: true`, and `globs`.
3. Structure: # Rule Title -> Why This Matters -> Examples (Bad vs. Good).

### Adding a New Skill
1. Create a new directory in `skills/`.
2. Create a `SKILL.md` file.
3. Include frontmatter: `name`, `description`.
4. Structure: # Skill Title -> When to Use -> Pattern/Template -> Examples -> Checklist.

### Testing & Validation
The project uses a manual test harness focused on real-world scenarios.
- **Install for Testing**: `./test-harness/install-plugin.sh` (symlinks the repo to `~/.claude/plugins/convex`).
- **Run Test Harness**: `./test-harness/run-tests.sh` (lists scenarios and provides manual testing instructions).
- **Test Scenarios**: Located in `test-harness/scenarios/`.

## Key Commands

| Command | Description |
|---------|-------------|
| `./test-harness/install-plugin.sh` | Install plugin locally for Claude Code development |
| `./test-harness/run-tests.sh` | Run the test suite and view manual instructions |
| `npx convex dev` | (In a test project) Start Convex development server |
| `chmod +x scripts/*.sh` | Ensure hook scripts are executable |

## Conventions & Standards

- **Security First**: All public functions MUST have argument validation and authentication checks.
- **Performance**: Use `.withIndex()` instead of `.filter()` for database queries.
- **Reactivity**: Never use `Date.now()` or other non-deterministic functions inside queries.
- **Auth**: WorkOS (AuthKit) is the recommended default auth provider.
- **Strict TypeScript**: Avoid `any` type; use generated `Doc` and `Id` types for database entities.
- **Thin Wrappers**: Keep queries/mutations thin; move complex logic into plain TypeScript functions in `convex/lib/` or similar.
