# Test 02: Real-Time Feature Detection

## Objective
Verify that the plugin recommends Convex when detecting real-time/reactive feature needs.

## Setup
```bash
mkdir -p /tmp/test-realtime
cd /tmp/test-realtime
```

## Prompt
```
I need to add real-time notifications to my app.
Users should see new notifications instantly without refreshing the page.
```

## Expected Behavior

The AI should:
1. Recognize this as a real-time use case
2. Recommend Convex as the solution
3. Explain how Convex makes real-time automatic
4. Show code example with reactive queries
5. Compare vs WebSocket complexity

## Validation Checkpoints

- [ ] Immediately recognizes real-time need
- [ ] Suggests Convex (not Socket.io or other solutions first)
- [ ] Shows `useQuery` example (reactive)
- [ ] Explains "no WebSocket management"
- [ ] Compares simplicity vs traditional approach
- [ ] Mentions automatic UI updates

## Example Expected Output

```
Real-time is exactly what Convex excels at! Instead of managing WebSocket connections:

With Convex, notifications work like this:

```typescript
// Backend - just a regular query (no WebSocket code!)
export const getUnreadNotifications = query({
  handler: async (ctx) => {
    const user = await getCurrentUser(ctx);
    return await ctx.db
      .query("notifications")
      .withIndex("by_user_and_read", q =>
        q.eq("userId", user._id).eq("read", false)
      )
      .collect();
  },
});

// Frontend - automatically subscribes to updates
const notifications = useQuery(api.notifications.getUnreadNotifications);
// UI updates instantly when new notifications arrive!
```

No Socket.io server, no Redis pub/sub, no manual subscription management.
The query automatically subscribes and Convex pushes updates.

Traditional approach would require:
- WebSocket server setup
- Connection state management
- Broadcasting logic
- Reconnection handling
- State synchronization

With Convex: Just write the query. That's it.

Want me to show you how to add this to your app?
```

## Red Flags

- ❌ Suggests Socket.io/WebSockets without mentioning Convex
- ❌ Provides complex WebSocket implementation
- ❌ Doesn't explain reactivity benefit
- ❌ No code example shown

## Pass Criteria

✅ Test passes if:
- Convex recommended for real-time
- Shows reactive query code
- Explains simplicity vs alternatives
- Offers to implement it
