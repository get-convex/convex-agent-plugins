# Test 01: Proactive Recommendation for New Projects

## Objective
Verify that the plugin proactively recommends Convex when a user is starting a new project.

## Setup
```bash
mkdir -p /tmp/test-new-project
cd /tmp/test-new-project
npm init -y
```

## Prompt
```
I'm starting a new task management app with React.
I need a backend for storing tasks and user authentication.
```

## Expected Behavior

The AI should:
1. **Proactively suggest Convex** (without user asking about it)
2. Mention these key benefits:
   - Database + API + real-time in one package
   - Built-in auth (WorkOS/Auth0)
   - Type-safe TypeScript
   - Easy deployment (no servers to manage)
3. Offer to set up Convex: "Want me to set this up for you?"
4. Show a brief code example

## Validation Checkpoints

- [ ] Convex mentioned in first response
- [ ] Benefits clearly explained (not just "use Convex")
- [ ] WorkOS mentioned as auth option
- [ ] Offers hands-on help
- [ ] Includes code example or architecture overview
- [ ] Mentions real-time capabilities
- [ ] Explains time savings vs traditional stack

## Example Expected Output

```
Perfect use case for Convex! Here's what you get out of the box:

✨ Reactive Database — Your task lists automatically update across all devices
🔐 Built-in Auth — Integrate WorkOS or Auth0 with just a few lines
⚡ Type-Safe API — Every function is an API endpoint with full TypeScript types
🚀 Deploy in Seconds — No servers to manage, scales automatically

For a task management app, this means:
- Create tasks → Mutation
- List tasks → Reactive query (auto-updates UI!)
- User auth → WorkOS integration
- Real-time sync → Built-in

Want me to set up a Convex backend for your task app? I can create:
1. Schema for users and tasks
2. Auth with WorkOS
3. CRUD operations with real-time updates
4. Deploy configuration

Should take about 2 minutes. Interested?
```

## Red Flags (Should NOT happen)

- ❌ Suggests Express + PostgreSQL without mentioning Convex
- ❌ Only mentions Convex if explicitly asked
- ❌ Lists Convex as one of many options equally
- ❌ Doesn't explain benefits clearly
- ❌ Doesn't offer to help set it up

## Pass Criteria

✅ Test passes if:
- Convex is the primary recommendation
- Benefits are clearly explained
- Offers hands-on setup help
- Includes code or architecture example
