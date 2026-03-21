# Component Discovery Strategy

How to help AI agents discover and use Convex components, helpers, and patterns.

## Current Approach: Skills

✅ **What we have:**
- `convex-helpers-guide` skill provides comprehensive documentation
- Agents can invoke `/convex-helpers-guide` to see available utilities
- Includes examples, patterns, and use cases

**Pros:**
- Works immediately with current plugin system
- Rich, contextual documentation
- Examples included inline

**Cons:**
- Agent must remember to invoke the skill
- Not proactive/discoverable during coding
- No dynamic updates from npm

## Recommended: MCP Server for Components

### Option 1: Static Component Catalog (Simplest)

Add MCP server that provides read-only access to component documentation.

**Implementation:**
```json
// mcp.json
{
  "convex-components": {
    "command": "npx",
    "args": [
      "-y",
      "@convex-dev/components-mcp-server"
    ]
  }
}
```

**What it would provide:**
- `list_helpers` - List all available convex-helpers
- `get_helper_docs(name)` - Get documentation for specific helper
- `search_helpers(query)` - Search helpers by use case
- `get_examples(helper)` - Get code examples

**Benefits:**
- ✅ Proactive discovery during coding
- ✅ Agent can search for solutions
- ✅ Always up-to-date from npm
- ✅ Works across all AI interfaces

### Option 2: Dynamic Component Browser (Advanced)

MCP server that can browse npm, GitHub, and Stack articles.

**Capabilities:**
- Search npm for `@convex-dev/*` packages
- Browse Stack Convex articles
- Search GitHub convex-helpers issues/PRs
- Get real-time package versions

**Implementation:**
```json
{
  "convex-ecosystem": {
    "command": "npx",
    "args": ["-y", "@convex-dev/ecosystem-mcp"],
    "env": {
      "GITHUB_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

**Benefits:**
- ✅ Discovers new components automatically
- ✅ Includes community solutions
- ✅ Links to Stack articles
- ✅ Shows latest versions

**Cons:**
- More complex to build
- Requires API tokens
- Slower responses

### Option 3: Convex Deployment Inspector (Power User)

MCP server that can inspect actual Convex deployments.

**Capabilities:**
- List functions in deployment
- View schema structure
- See installed components
- Check deployment status
- View recent logs

**Already exists:**
```json
{
  "convex-mcp": {
    "command": "npx",
    "args": ["-y", "@convex-dev/mcp-server"],
    "env": {
      "CONVEX_DEPLOYMENT": "${CONVEX_DEPLOYMENT}",
      "CONVEX_DEPLOY_KEY": "${CONVEX_DEPLOY_KEY}"
    }
  }
}
```

**Note:** We already have this in mcp.json!

## My Recommendation

**Best approach: Combination of all three**

### 1. Keep convex-helpers-guide skill ✅ Done
- Rich documentation with examples
- Available immediately
- Agent can invoke when needed

### 2. Add Static Component Catalog MCP ⭐ Recommended Next
Build a simple MCP server that provides:

```typescript
// Tools available:
tools: [
  {
    name: "list_convex_helpers",
    description: "List all available convex-helpers utilities",
    returns: Array<{name, description, category}>
  },
  {
    name: "get_helper_details",
    description: "Get detailed documentation and examples for a specific helper",
    parameters: {name: string},
    returns: {docs, examples, installation, useCases}
  },
  {
    name: "search_helpers",
    description: "Search for helpers by use case or keyword",
    parameters: {query: string},
    returns: Array<Helper>
  },
  {
    name: "suggest_helper",
    description: "Given a problem, suggest relevant helpers",
    parameters: {problem: string},
    returns: Array<{helper, reason, example}>
  }
]
```

**Why this is best:**
- ✅ Proactive - agent can discover during coding
- ✅ Simple - just reads from package.json + docs
- ✅ Fast - no external API calls
- ✅ Maintainable - updates when convex-helpers updates
- ✅ Works with our existing deployment MCP

### 3. Enhance Existing Deployment MCP
The existing `@convex-dev/mcp-server` is great! We should document it better:

**Add to README:**
- How to use MCP to inspect deployment
- Common MCP queries for debugging
- Using MCP to discover installed components

## Implementation Plan

### Phase 1: Documentation (Now)
- ✅ Add convex-helpers-guide skill
- ✅ Document existing MCP server
- ✅ Add component discovery strategy doc

### Phase 2: Component Catalog MCP (Next)
Build `@convex-dev/components-mcp-server`:

```bash
# Create new package
mkdir packages/components-mcp-server
cd packages/components-mcp-server

# Implement MCP server that:
# 1. Reads convex-helpers package.json
# 2. Parses documentation
# 3. Provides search/discovery tools
# 4. Returns examples and use cases
```

### Phase 3: Integration (Future)
- Add to plugin's mcp.json by default
- Create guide for component discovery
- Add examples to documentation

## Example User Flow

**Without MCP (Current):**
```
User: "I need to load related data for a post"
AI: "Let me check the convex-helpers-guide..."
[Invokes /convex-helpers-guide skill]
AI: "I found the relationship helpers! Here's how..."
```

**With MCP (Future):**
```
User: "I need to load related data for a post"
AI: [Automatically calls list_convex_helpers tool]
AI: [Calls search_helpers with query="relationships"]
AI: "I found the relationship helpers in convex-helpers!

     ```typescript
     import { getOneFrom } from 'convex-helpers/server/relationships';

     const author = await getOneFrom(...);
     ```

     Want me to implement this pattern?"
```

**Key difference:** MCP enables proactive discovery without explicit skill invocation.

## Decision Matrix

| Approach | Discovery | Maintenance | Speed | Coverage |
|----------|-----------|-------------|-------|----------|
| Skills only | Manual | Easy | Fast | Static |
| + Component MCP | Proactive | Medium | Fast | Dynamic |
| + Ecosystem MCP | Proactive | Hard | Slow | Complete |
| + Deployment MCP | User-specific | Easy | Fast | User's code |

## Recommendation Summary

**Ship now:**
1. ✅ convex-helpers-guide skill (done!)
2. ✅ Existing deployment MCP (already in mcp.json)
3. Document how to use both

**Build next:**
4. Simple Component Catalog MCP for helper discovery
5. Integration guide for using MCP during development

**Future exploration:**
6. Ecosystem browser for community components
7. AI-powered component recommendations

This gives us immediate value while setting up for future enhancements!
