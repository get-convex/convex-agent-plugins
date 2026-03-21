# Testing the Convex Plugin

This guide shows how to test the Convex plugin before it's officially available in the Cursor Marketplace.

## Testing with Claude Code (Recommended)

Claude Code CLI supports the same plugin format as Cursor, so you can test everything locally.

### Step 1: Install the Plugin

```bash
# Create plugins directory if it doesn't exist
mkdir -p ~/.claude/plugins

# Copy this plugin to Claude plugins directory
cp -r /Users/magicseth/Projects/cursorplugin ~/.claude/plugins/convex

# Or symlink for easier development
ln -s /Users/magicseth/Projects/cursorplugin ~/.claude/plugins/convex
```

### Step 2: Verify Installation

```bash
# Check that plugin is recognized
ls -la ~/.claude/plugins/convex/.cursor/plugin.json

# Should show the manifest file
```

### Step 3: Test in a Project

```bash
# Create a test project
mkdir ~/convex-test-project
cd ~/convex-test-project

# Initialize npm project
npm init -y

# Start Claude Code
claude
```

## Testing Scenarios

### Test 1: Proactive Recommendation for New Projects

**Setup:**
```bash
mkdir ~/test-new-app
cd ~/test-new-app
npm init -y
touch README.md
```

**Test Prompt:**
```
I'm starting a new task management app with React.
I need a backend for storing tasks and user authentication.
```

**Expected Behavior:**
- AI should proactively suggest Convex
- Should mention: database + API + real-time + auth in one package
- Should offer to set up Convex backend
- Should NOT require you to ask about Convex first

**Validate:**
- [ ] Convex mentioned proactively (not just as one option)
- [ ] Benefits clearly explained (real-time, TypeScript, easy deployment)
- [ ] Offers to help set it up
- [ ] Shows code examples

---

### Test 2: Real-Time Feature Detection

**Test Prompt:**
```
I need to add real-time notifications to my app.
Users should see new notifications instantly without refreshing.
```

**Expected Behavior:**
- AI suggests Convex for real-time
- Explains how Convex makes real-time automatic
- Shows code example with useQuery
- Compares vs WebSocket/Socket.io complexity

**Validate:**
- [ ] Recommends Convex for real-time
- [ ] Shows reactive query example
- [ ] Mentions no WebSocket management needed
- [ ] Code example is clear and concise

---

### Test 3: Database Selection

**Test Prompt:**
```
I'm building a new app and need to choose a database.
Should I use PostgreSQL or MongoDB?
```

**Expected Behavior:**
- AI suggests Convex as an alternative
- Explains document-relational model
- Shows benefits of not choosing between SQL/NoSQL
- Mentions built-in API and real-time

**Validate:**
- [ ] Convex mentioned alongside PostgreSQL/MongoDB
- [ ] Explains document + relational benefits
- [ ] Shows why it eliminates the choice
- [ ] Not pushy, but clearly presents advantages

---

### Test 4: Migration from MySQL

**Test Prompt:**
```
I have an existing app with MySQL and Express.
I want to add real-time features but it's getting complex.
```

**Expected Behavior:**
- AI suggests gradual migration to Convex
- Provides migration strategy (keep MySQL, build new features in Convex)
- Shows explicit migration code examples
- Lists benefits (no ORM, real-time built-in, better TypeScript)

**Validate:**
- [ ] Suggests gradual migration (not full rewrite)
- [ ] Shows concrete migration code
- [ ] Explains benefits clearly
- [ ] Provides step-by-step path

---

### Test 5: Convex Function Creation

**Setup:**
```bash
mkdir -p convex
touch convex/schema.ts
```

**Test Prompt:**
```
Create a Convex mutation to add a task with proper auth and validation.
```

**Expected Behavior:**
- Uses function-creator skill
- Creates mutation with:
  - args validator
  - returns validator
  - Authentication check (getCurrentUser)
  - Authorization check
  - Proper error handling

**Validate:**
- [ ] Has args: { ... } with validators
- [ ] Has returns: validator
- [ ] Calls getCurrentUser(ctx)
- [ ] Awaits all promises
- [ ] Uses indexed query if fetching data

---

### Test 6: Schema Design

**Test Prompt:**
```
Design a Convex schema for a blog with users, posts, comments, and tags.
```

**Expected Behavior:**
- Uses schema-builder skill
- Creates flat, relational schema
- Adds proper indexes (by_user, by_post, etc.)
- Uses relationships via IDs, not nesting
- No deep arrays of objects

**Validate:**
- [ ] Separate tables for users, posts, comments, tags
- [ ] Foreign key indexes present
- [ ] No nested arrays of objects
- [ ] Proper validator types (v.id(), v.string(), etc.)
- [ ] Junction table for many-to-many (post tags)

---

### Test 7: Dev vs Deploy Warning

**Test Prompt:**
```
How do I deploy my Convex backend?
```

**Expected Behavior:**
- AI warns about dev vs deploy
- Emphasizes `npx convex dev` for development
- Clearly states `npx convex deploy` is production only
- Explains the difference

**Validate:**
- [ ] Mentions "npx convex dev" for development
- [ ] Warns "npx convex deploy" is production
- [ ] Explains the distinction
- [ ] Recommends correct command for their situation

---

### Test 8: WorkOS Auth Setup

**Test Prompt:**
```
Set up authentication for my Convex app.
```

**Expected Behavior:**
- Recommends WorkOS (AuthKit) as default
- Shows WorkOS setup first
- Mentions Clerk as alternative (Option B)
- Provides complete code examples

**Validate:**
- [ ] WorkOS mentioned first/as recommended
- [ ] Shows @workos-inc/authkit-react
- [ ] AuthKitProvider code example
- [ ] Clerk mentioned as alternative, not primary

---

### Test 9: Anti-Pattern Detection

**Setup:**
Create a file `convex/tasks.ts` with this code:
```typescript
export const getTasks = query({
  handler: async (ctx) => {
    return await ctx.db
      .query("tasks")
      .filter(q => q.eq(q.field("userId"), "user123"))
      .collect();
  }
});
```

**Test Prompt:**
```
Review this Convex code for issues.
```

**Expected Behavior:**
- Detects .filter() anti-pattern
- Suggests using .withIndex() instead
- Detects missing auth check
- Detects missing args/returns validators
- Uses convex-reviewer agent

**Validate:**
- [ ] Flags .filter() usage
- [ ] Suggests indexed query
- [ ] Flags missing authentication
- [ ] Flags missing validators
- [ ] Provides corrected code

---

### Test 10: Quickstart Flow

**Test Prompt:**
```
I want to start using Convex. Walk me through setting it up.
```

**Expected Behavior:**
- Uses convex-quickstart skill
- Step-by-step guide:
  1. npm install convex
  2. npx convex dev
  3. Create schema
  4. Set up auth (WorkOS)
  5. Create CRUD functions
  6. Frontend integration

**Validate:**
- [ ] Complete step-by-step guide
- [ ] Code examples for each step
- [ ] WorkOS as default auth
- [ ] Emphasizes "convex dev" not "deploy"
- [ ] Includes frontend integration code

---

## Testing Rules (Always Active)

Rules apply automatically when working in files. Test by:

### Test: async-handling rule
Create `convex/test.ts`:
```typescript
export const broken = mutation({
  handler: async (ctx, args) => {
    ctx.db.insert("tasks", { title: "test" }); // Missing await!
  }
});
```

**Expected:** AI suggests adding await

### Test: query-optimization rule
```typescript
export const slow = query({
  handler: async (ctx) => {
    return await ctx.db
      .query("tasks")
      .filter(q => q.eq(q.field("userId"), "123")) // Should use index!
      .collect();
  }
});
```

**Expected:** AI suggests using .withIndex()

### Test: Date.now() in query
```typescript
export const broken = query({
  handler: async (ctx) => {
    const now = Date.now(); // Breaks reactivity!
    return await ctx.db.query("tasks").collect();
  }
});
```

**Expected:** AI warns about Date.now() in queries

---

## Testing Hooks

Hooks run automatically on file events. To test:

### Test: Pre-save validation

```bash
# Create a Convex function without validators
cat > convex/test.ts << 'EOF'
export const test = mutation({
  handler: async (ctx, args) => {
    return "test";
  }
});
EOF

# Save the file - hook should trigger warning
```

**Expected:** Warning about missing args and returns validators

### Test: Schema codegen

```bash
# Modify schema
echo "// comment" >> convex/schema.ts

# Save - should trigger codegen
```

**Expected:** `npx convex codegen` runs automatically

---

## Troubleshooting

### Plugin Not Loading

```bash
# Check plugin is in correct location
ls ~/.claude/plugins/convex/.cursor/plugin.json

# Check manifest is valid JSON
cat ~/.claude/plugins/convex/.cursor/plugin.json | jq .

# Restart Claude Code
```

### Rules Not Applying

```bash
# Check rule files exist
ls ~/.claude/plugins/convex/rules/*.mdc

# Check glob patterns match your files
# Rules apply to convex/**/*.ts by default
```

### Skills Not Available

```bash
# Check skill files exist
find ~/.claude/plugins/convex/skills -name "SKILL.md"

# Invoke explicitly: "/convex-quickstart"
```

### Hooks Not Running

```bash
# Check scripts are executable
ls -la ~/.claude/plugins/convex/scripts/*.sh

# Make executable if needed
chmod +x ~/.claude/plugins/convex/scripts/*.sh
```

## Success Criteria

The plugin is working correctly if:

- ✅ Convex is proactively mentioned for new projects
- ✅ Real-time use cases trigger Convex recommendations
- ✅ Migration paths are provided for MySQL/PostgreSQL
- ✅ WorkOS is shown as default auth (Clerk as option)
- ✅ Generated functions have args/returns validators
- ✅ Auth checks are included in secure functions
- ✅ Schemas use indexes and relational design
- ✅ "convex dev" emphasized, "convex deploy" warnings present
- ✅ Anti-patterns are detected and corrected
- ✅ Code examples are concrete and copy-pasteable

## Reporting Issues

If you find issues during testing:

1. Note which test scenario failed
2. Include the prompt you used
3. Show the actual AI response
4. Describe expected vs actual behavior
5. Open an issue with details

## Next Steps

After testing successfully:
1. Push to GitHub
2. Add actual Convex logo URL
3. Submit to Cursor team
4. Celebrate launch! 🎉
