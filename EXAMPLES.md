# Convex Plugin Examples

Real-world examples of using the Convex plugin in Cursor.

## Example 1: Building a Task Manager

### Step 1: Create the Schema

**Prompt:**
```
Create a Convex schema for a task manager with:
- Users table
- Tasks table with owner, title, description, status, and due date
- Users can have multiple tasks
- Tasks should be queryable by user and status
```

**Result:** The schema-builder skill generates:

```typescript
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    tokenIdentifier: v.string(),
    name: v.string(),
    email: v.string(),
    createdAt: v.number(),
  })
    .index("by_token", ["tokenIdentifier"])
    .index("by_email", ["email"]),

  tasks: defineTable({
    userId: v.id("users"),
    title: v.string(),
    description: v.optional(v.string()),
    status: v.union(
      v.literal("todo"),
      v.literal("in_progress"),
      v.literal("done")
    ),
    dueDate: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_user_and_status", ["userId", "status"])
    .index("by_status", ["status"]),
});
```

### Step 2: Set Up Authentication

**Prompt:**
```
Set up WorkOS authentication with a getCurrentUser helper and storeUser mutation
```

**Result:** The auth-setup skill generates auth helpers and user management.

### Step 3: Create Task Functions

**Prompt:**
```
Create these functions:
1. Query to get all tasks for the current user
2. Mutation to create a new task
3. Mutation to update task status
4. Mutation to delete a task (with ownership check)
```

**Result:** The function-creator skill generates secure, validated functions:

```typescript
// Get user's tasks
export const getMyTasks = query({
  args: {
    status: v.optional(v.union(
      v.literal("todo"),
      v.literal("in_progress"),
      v.literal("done")
    )),
  },
  returns: v.array(v.object({
    _id: v.id("tasks"),
    title: v.string(),
    description: v.optional(v.string()),
    status: v.union(
      v.literal("todo"),
      v.literal("in_progress"),
      v.literal("done")
    ),
    dueDate: v.optional(v.number()),
    createdAt: v.number(),
  })),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    if (args.status) {
      return await ctx.db
        .query("tasks")
        .withIndex("by_user_and_status", q =>
          q.eq("userId", user._id).eq("status", args.status)
        )
        .collect();
    }

    return await ctx.db
      .query("tasks")
      .withIndex("by_user", q => q.eq("userId", user._id))
      .collect();
  },
});

// Create task
export const createTask = mutation({
  args: {
    title: v.string(),
    description: v.optional(v.string()),
    dueDate: v.optional(v.number()),
  },
  returns: v.id("tasks"),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    return await ctx.db.insert("tasks", {
      userId: user._id,
      title: args.title,
      description: args.description,
      dueDate: args.dueDate,
      status: "todo",
      createdAt: Date.now(),
    });
  },
});

// Update task status
export const updateTaskStatus = mutation({
  args: {
    taskId: v.id("tasks"),
    status: v.union(
      v.literal("todo"),
      v.literal("in_progress"),
      v.literal("done")
    ),
  },
  returns: v.id("tasks"),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    const task = await ctx.db.get(args.taskId);
    if (!task) throw new Error("Task not found");

    if (task.userId !== user._id) {
      throw new Error("You can only update your own tasks");
    }

    await ctx.db.patch(args.taskId, { status: args.status });
    return args.taskId;
  },
});

// Delete task
export const deleteTask = mutation({
  args: { taskId: v.id("tasks") },
  returns: v.null(),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);

    const task = await ctx.db.get(args.taskId);
    if (!task) throw new Error("Task not found");

    if (task.userId !== user._id) {
      throw new Error("You can only delete your own tasks");
    }

    await ctx.db.delete(args.taskId);
    return null;
  },
});
```

## Example 2: Adding Team Collaboration

### Extending the Schema

**Prompt:**
```
Extend the schema to add:
- Teams table
- Team membership with roles (owner, member)
- Tasks belong to teams instead of individual users
- Support querying tasks by team
```

**Result:**

```typescript
export default defineSchema({
  // ... existing users table ...

  teams: defineTable({
    name: v.string(),
    ownerId: v.id("users"),
    createdAt: v.number(),
  }).index("by_owner", ["ownerId"]),

  teamMembers: defineTable({
    teamId: v.id("teams"),
    userId: v.id("users"),
    role: v.union(v.literal("owner"), v.literal("member")),
    joinedAt: v.number(),
  })
    .index("by_team", ["teamId"])
    .index("by_user", ["userId"])
    .index("by_team_and_user", ["teamId", "userId"]),

  tasks: defineTable({
    teamId: v.id("teams"),
    createdBy: v.id("users"),
    title: v.string(),
    description: v.optional(v.string()),
    status: v.union(
      v.literal("todo"),
      v.literal("in_progress"),
      v.literal("done")
    ),
    assignedTo: v.optional(v.id("users")),
    dueDate: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_team", ["teamId"])
    .index("by_team_and_status", ["teamId", "status"])
    .index("by_assigned", ["assignedTo"]),
});
```

### Migrating Existing Data

**Prompt:**
```
Create a migration to move tasks from userId to teamId.
Each user should have a personal team, and their tasks should move there.
```

**Result:** The migration-helper skill generates a safe migration plan.

## Example 3: Adding Real-Time Notifications

**Prompt:**
```
Add a notifications system where:
- Users get notified when assigned a task
- Notifications are marked as read/unread
- Query to get unread notifications count
```

**Result:**

```typescript
// Schema addition
notifications: defineTable({
  userId: v.id("users"),
  type: v.union(
    v.literal("task_assigned"),
    v.literal("task_completed")
  ),
  taskId: v.id("tasks"),
  message: v.string(),
  read: v.boolean(),
  createdAt: v.number(),
})
  .index("by_user", ["userId"])
  .index("by_user_and_read", ["userId", "read"]),

// Functions
export const getUnreadCount = query({
  args: {},
  returns: v.number(),
  handler: async (ctx) => {
    const user = await getCurrentUser(ctx);
    const notifications = await ctx.db
      .query("notifications")
      .withIndex("by_user_and_read", q =>
        q.eq("userId", user._id).eq("read", false)
      )
      .collect();
    return notifications.length;
  },
});

export const markNotificationRead = mutation({
  args: { notificationId: v.id("notifications") },
  returns: v.null(),
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    const notification = await ctx.db.get(args.notificationId);

    if (!notification) throw new Error("Notification not found");
    if (notification.userId !== user._id) {
      throw new Error("Unauthorized");
    }

    await ctx.db.patch(args.notificationId, { read: true });
    return null;
  },
});
```

## Example 4: Code Review

After writing your functions, use the Convex reviewer agent:

**Prompt:**
```
Review my Convex functions for security and performance issues
```

The convex-reviewer agent will check:
- ✅ Auth and authorization
- ✅ Argument validation
- ✅ Query optimization
- ✅ Common anti-patterns

## Tips for Best Results

1. **Be specific:** Instead of "create a backend," say "create a task management backend with users, tasks, and auth"

2. **Ask for reviews:** After generating code, ask the reviewer agent to check it

3. **Iterate:** Start simple, then extend. The plugin excels at incremental improvements

4. **Use skills explicitly:** When you want specialized help, mention the skill by name

5. **Follow the patterns:** The plugin teaches Convex best practices—trust the guidance

## Common Workflows

### Starting a New Project
```
1. "Create a schema for [your app]"
2. "Set up authentication with WorkOS"
3. "Create CRUD operations for [resource]"
4. "Review my code for issues"
```

### Adding Features
```
1. "Add [feature] to my schema"
2. "Create functions for [feature]"
3. "How should I migrate existing data?"
```

### Optimizing
```
1. "Review my queries for performance"
2. "Which indexes should I add?"
3. "Is this query reactive-safe?"
```

### Fixing Issues
```
1. "My query is slow, help optimize it"
2. "How do I add auth to this function?"
3. "Migrate this array to a separate table"
```
