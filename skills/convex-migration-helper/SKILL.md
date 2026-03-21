---
name: convex-migration-helper
description: Plan and execute Convex schema migrations safely, including adding fields, creating tables, and data transformations. Use when schema changes affect existing data.
---

# Convex Migration Helper

Safely migrate Convex schemas and data when making breaking changes.

## When to Use

- Adding new required fields to existing tables
- Changing field types or structure
- Splitting or merging tables
- Renaming or deleting fields
- Migrating from nested to relational data

## Key Concepts

### Schema Validation Drives the Workflow

Convex will not let you deploy a schema that does not match the data at rest. This is the fundamental constraint that shapes every migration:

- You cannot add a required field if existing documents don't have it
- You cannot change a field's type if existing documents have the old type
- You cannot remove a field from the schema if existing documents still have it

This means migrations follow a predictable pattern: **widen the schema, migrate the data, narrow the schema**.

### Online Migrations

Convex migrations run online, meaning the app continues serving requests while data is updated asynchronously in batches. During the migration window, your code must handle both old and new data formats.

### Prefer New Fields Over Changing Types

When changing the shape of data, create a new field rather than modifying an existing one. This makes the transition safer and easier to roll back.

### Don't Delete Data

Unless you are certain, prefer deprecating fields over deleting them. Mark the field as `v.optional` and add a code comment explaining it is deprecated and why it existed.

## Safe Changes (No Migration Needed)

### Adding Optional Field

```typescript
// Before
users: defineTable({
  name: v.string(),
})

// After - safe, new field is optional
users: defineTable({
  name: v.string(),
  bio: v.optional(v.string()),
})
```

### Adding New Table

```typescript
posts: defineTable({
  userId: v.id("users"),
  title: v.string(),
}).index("by_user", ["userId"])
```

### Adding Index

```typescript
users: defineTable({
  name: v.string(),
  email: v.string(),
})
  .index("by_email", ["email"])
```

## Breaking Changes: The Deployment Workflow

Every breaking migration follows the same multi-deploy pattern:

**Deploy 1 - Widen the schema:**

1. Update schema to allow both old and new formats (e.g., add optional new field)
2. Update code to handle both formats when reading
3. Update code to write the new format for new documents
4. Deploy

**Between deploys - Migrate data:**

5. Run migration to backfill existing documents
6. Verify all documents are migrated

**Deploy 2 - Narrow the schema:**

7. Update schema to require the new format only
8. Remove code that handles the old format
9. Deploy

## Using the Migrations Component (Recommended)

For any non-trivial migration, use the [`@convex-dev/migrations`](https://www.convex.dev/components/migrations) component. It handles batching, cursor-based pagination, state tracking, resume from failure, dry runs, and progress monitoring.

### Installation

```bash
npm install @convex-dev/migrations
```

### Setup

```typescript
// convex/convex.config.ts
import { defineApp } from "convex/server";
import migrations from "@convex-dev/migrations/convex.config.js";

const app = defineApp();
app.use(migrations);
export default app;
```

```typescript
// convex/migrations.ts
import { Migrations } from "@convex-dev/migrations";
import { components } from "./_generated/api.js";
import { DataModel } from "./_generated/dataModel.js";

export const migrations = new Migrations<DataModel>(components.migrations);
export const run = migrations.runner();
```

The `DataModel` type parameter is optional but provides type safety for migration definitions.

### Define a Migration

The `migrateOne` function processes a single document. The component handles batching and pagination automatically.

```typescript
// convex/migrations.ts
export const addDefaultRole = migrations.define({
  table: "users",
  migrateOne: async (ctx, user) => {
    if (user.role === undefined) {
      await ctx.db.patch(user._id, { role: "user" });
    }
  },
});
```

Shorthand: if you return an object, it is applied as a patch automatically.

```typescript
export const clearDeprecatedField = migrations.define({
  table: "users",
  migrateOne: () => ({ legacyField: undefined }),
});
```

### Run a Migration

From the CLI:

```bash
# Define a one-off runner in convex/migrations.ts:
#   export const runIt = migrations.runner(internal.migrations.addDefaultRole);
npx convex run migrations:runIt

# Or use the general-purpose runner
npx convex run migrations:run '{"fn": "migrations:addDefaultRole"}'
```

Programmatically from another Convex function:

```typescript
await migrations.runOne(ctx, internal.migrations.addDefaultRole);
```

### Run Multiple Migrations in Order

```typescript
export const runAll = migrations.runner([
  internal.migrations.addDefaultRole,
  internal.migrations.clearDeprecatedField,
  internal.migrations.normalizeEmails,
]);
```

```bash
npx convex run migrations:runAll
```

If one fails, it stops and will not continue to the next. Call it again to retry from where it left off. Completed migrations are skipped automatically.

### Dry Run

Test a migration before committing changes:

```bash
npx convex run migrations:runIt '{"dryRun": true}'
```

This runs one batch and then rolls back, so you can see what it would do without changing any data.

### Check Migration Status

```bash
npx convex run --component migrations lib:getStatus --watch
```

### Cancel a Running Migration

```bash
npx convex run --component migrations lib:cancel '{"name": "migrations:addDefaultRole"}'
```

Or programmatically:

```typescript
await migrations.cancel(ctx, internal.migrations.addDefaultRole);
```

### Run Migrations on Deploy

Chain migration execution after deploying:

```bash
npx convex deploy --cmd 'npm run build' && npx convex run migrations:runAll --prod
```

### Configuration Options

#### Custom Batch Size

If documents are large or the table has heavy write traffic, reduce the batch size to avoid transaction limits or OCC conflicts:

```typescript
export const migrateHeavyTable = migrations.define({
  table: "largeDocuments",
  batchSize: 10,
  migrateOne: async (ctx, doc) => {
    // migration logic
  },
});
```

#### Migrate a Subset Using an Index

Process only matching documents instead of the full table:

```typescript
export const fixEmptyNames = migrations.define({
  table: "users",
  customRange: (query) =>
    query.withIndex("by_name", (q) => q.eq("name", "")),
  migrateOne: () => ({ name: "<unknown>" }),
});
```

#### Parallelize Within a Batch

By default each document in a batch is processed serially. Enable parallel processing if your migration logic does not depend on ordering:

```typescript
export const clearField = migrations.define({
  table: "myTable",
  parallelize: true,
  migrateOne: () => ({ optionalField: undefined }),
});
```

## Common Migration Patterns

### Adding a Required Field

```typescript
// Deploy 1: Schema allows both states
users: defineTable({
  name: v.string(),
  role: v.optional(v.union(v.literal("user"), v.literal("admin"))),
})

// Migration: backfill the field
export const addDefaultRole = migrations.define({
  table: "users",
  migrateOne: async (ctx, user) => {
    if (user.role === undefined) {
      await ctx.db.patch(user._id, { role: "user" });
    }
  },
});

// Deploy 2: After migration completes, make it required
users: defineTable({
  name: v.string(),
  role: v.union(v.literal("user"), v.literal("admin")),
})
```

### Deleting a Field

Mark the field optional first, migrate data to remove it, then remove from schema:

```typescript
// Deploy 1: Make optional
// isPro: v.boolean()  -->  isPro: v.optional(v.boolean())

// Migration
export const removeIsPro = migrations.define({
  table: "teams",
  migrateOne: async (ctx, team) => {
    if (team.isPro !== undefined) {
      await ctx.db.patch(team._id, { isPro: undefined });
    }
  },
});

// Deploy 2: Remove isPro from schema entirely
```

### Changing a Field Type

Prefer creating a new field. You can combine adding and deleting in one migration:

```typescript
// Deploy 1: Add new field, keep old field optional
// isPro: v.boolean()  -->  isPro: v.optional(v.boolean()), plan: v.optional(...)

// Migration: convert old field to new field
export const convertToEnum = migrations.define({
  table: "teams",
  migrateOne: async (ctx, team) => {
    if (team.plan === undefined) {
      await ctx.db.patch(team._id, {
        plan: team.isPro ? "pro" : "basic",
        isPro: undefined,
      });
    }
  },
});

// Deploy 2: Remove isPro from schema, make plan required
```

### Splitting Nested Data Into a Separate Table

```typescript
export const extractPreferences = migrations.define({
  table: "users",
  migrateOne: async (ctx, user) => {
    if (user.preferences === undefined) return;

    const existing = await ctx.db
      .query("userPreferences")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .first();

    if (!existing) {
      await ctx.db.insert("userPreferences", {
        userId: user._id,
        ...user.preferences,
      });
    }

    await ctx.db.patch(user._id, { preferences: undefined });
  },
});
```

Make sure your code is already writing to the new `userPreferences` table for new users before running this migration, so you don't miss documents created during the migration window.

### Cleaning Up Orphaned Documents

```typescript
export const deleteOrphanedEmbeddings = migrations.define({
  table: "embeddings",
  migrateOne: async (ctx, doc) => {
    const chunk = await ctx.db
      .query("chunks")
      .withIndex("by_embedding", (q) => q.eq("embeddingId", doc._id))
      .first();

    if (!chunk) {
      await ctx.db.delete(doc._id);
    }
  },
});
```

## Migration Strategies for Zero Downtime

During the migration window, your app must handle both old and new data formats. There are two main strategies.

### Dual Write (Preferred)

Write to both old and new structures. Read from the old structure until migration is complete.

1. Deploy code that writes both formats, reads old format
2. Run migration on existing data
3. Deploy code that reads new format, still writes both
4. Deploy code that only reads and writes new format

This is preferred because you can safely roll back at any point, the old format is always up to date.

```typescript
// Bad: only writing to new structure before migration is done
export const createTeam = mutation({
  args: { name: v.string(), isPro: v.boolean() },
  handler: async (ctx, args) => {
    await ctx.db.insert("teams", {
      name: args.name,
      plan: args.isPro ? "pro" : "basic",
    });
  },
});

// Good: writing to both structures during migration
export const createTeam = mutation({
  args: { name: v.string(), isPro: v.boolean() },
  handler: async (ctx, args) => {
    const plan = args.isPro ? "pro" : "basic";
    await ctx.db.insert("teams", {
      name: args.name,
      isPro: args.isPro,
      plan,
    });
  },
});
```

### Dual Read

Read both formats. Write only the new format.

1. Deploy code that reads both formats (preferring new), writes only new format
2. Run migration on existing data
3. Deploy code that reads and writes only new format

This avoids duplicating writes, which is useful when having two copies of data could cause inconsistencies. The downside is that rolling back to before step 1 is harder, since new documents only have the new format.

```typescript
// Good: reading both formats, preferring new
function getTeamPlan(team: Doc<"teams">): "basic" | "pro" {
  if (team.plan !== undefined) return team.plan;
  return team.isPro ? "pro" : "basic";
}
```

## Small Table Shortcut

For small tables (a few thousand documents at most), you can migrate in a single `internalMutation` without the component:

```typescript
import { internalMutation } from "./_generated/server";

export const backfillSmallTable = internalMutation({
  handler: async (ctx) => {
    const docs = await ctx.db.query("smallConfig").collect();
    for (const doc of docs) {
      if (doc.newField === undefined) {
        await ctx.db.patch(doc._id, { newField: "default" });
      }
    }
  },
});
```

```bash
npx convex run migrations:backfillSmallTable
```

Only use `.collect()` when you are certain the table is small. For anything larger, use the migrations component.

## Verifying a Migration

Query to check remaining unmigrated documents:

```typescript
import { query } from "./_generated/server";

export const verifyMigration = query({
  handler: async (ctx) => {
    const remaining = await ctx.db
      .query("users")
      .filter((q) => q.eq(q.field("role"), undefined))
      .take(10);

    return {
      complete: remaining.length === 0,
      sampleRemaining: remaining.map((u) => u._id),
    };
  },
});
```

Or use the component's built-in status monitoring:

```bash
npx convex run --component migrations lib:getStatus --watch
```

## Migration Checklist

- [ ] Identify the breaking change and plan the multi-deploy workflow
- [ ] Update schema to allow both old and new formats
- [ ] Update code to handle both formats when reading
- [ ] Update code to write the new format for new documents
- [ ] Deploy widened schema and updated code
- [ ] Define migration using the `@convex-dev/migrations` component
- [ ] Test with `dryRun: true`
- [ ] Run migration and monitor status
- [ ] Verify all documents are migrated
- [ ] Update schema to require new format only
- [ ] Clean up code that handled old format
- [ ] Deploy final schema and code
- [ ] Remove migration code once confirmed stable

## Common Pitfalls

1. **Don't make a field required before migrating data**: Convex will reject the deploy. Always widen the schema first.
2. **Don't `.collect()` large tables**: Use the migrations component for proper batched pagination. `.collect()` is only safe for tables you know are small.
3. **Don't forget to write the new format before migrating**: If your code doesn't write the new format for new documents, documents created during the migration window will be missed.
4. **Don't skip the dry run**: Use `dryRun: true` to validate your migration logic before committing changes to production data.
5. **Don't delete fields prematurely**: Prefer deprecating with `v.optional` and a comment. Only delete after you are confident the data is no longer needed.
6. **Don't use crons for migration batches**: The migrations component handles batching via recursive scheduling internally. Crons require manual cleanup and an extra deploy to remove.
