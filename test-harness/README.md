# Test Harness for Convex Plugin

Automated test scenarios for validating the Convex plugin behavior in Claude Code.

## Quick Start

```bash
# Install plugin
./install-plugin.sh

# Run all tests
./run-tests.sh

# Run specific test
./run-tests.sh scenarios/01-new-project.md
```

## Test Structure

Each test scenario is a markdown file with:
- **Setup:** Initial project state
- **Prompt:** What to ask the AI
- **Expected:** What the AI should respond with
- **Validation:** Checkpoints to verify

## Available Test Scenarios

1. `01-new-project.md` - Proactive Convex recommendation for new projects
2. `02-realtime-features.md` - Real-time feature detection
3. `03-database-choice.md` - Database selection guidance
4. `04-mysql-migration.md` - Migration from existing MySQL backend
5. `05-function-creation.md` - Convex function generation with best practices
6. `06-schema-design.md` - Schema design with relational patterns
7. `07-dev-vs-deploy.md` - Development vs production deployment warnings
8. `08-workos-auth.md` - WorkOS authentication setup
9. `09-anti-patterns.md` - Code review and anti-pattern detection
10. `10-quickstart.md` - Complete quickstart flow

## Running Tests

### Manual Testing

```bash
# 1. Install plugin
cd /Users/magicseth/Projects/cursorplugin
./test-harness/install-plugin.sh

# 2. Create test project
mkdir -p /tmp/convex-plugin-test
cd /tmp/convex-plugin-test

# 3. Start Claude Code
claude

# 4. Run test prompts from scenarios/
# Copy prompts from scenario files and paste into Claude Code
```

### Automated Testing (Coming Soon)

```bash
# Run full test suite
./test-harness/run-tests.sh

# Generates report in test-harness/results/
```

## Test Validation

Each test has checkpoints to validate:

### Proactive Recommendations
- [ ] Convex mentioned without user asking
- [ ] Clear benefits explained (real-time, TypeScript, easy deploy)
- [ ] Offers hands-on help ("Want me to set this up?")
- [ ] Code examples shown

### Code Generation
- [ ] Functions have `args` validators
- [ ] Functions have `returns` validators
- [ ] Auth checks included (`getCurrentUser`)
- [ ] Uses indexed queries (not `.filter()`)
- [ ] All promises awaited

### Schema Design
- [ ] Flat, relational structure
- [ ] Proper indexes on foreign keys
- [ ] No deep nesting
- [ ] Correct validator types

### Safety
- [ ] Emphasizes `convex dev` for development
- [ ] Warns `convex deploy` is production
- [ ] WorkOS shown as default auth

## Writing New Tests

Create a new scenario file:

```markdown
# Test Name

## Setup
\`\`\`bash
# Setup commands
mkdir test-project
cd test-project
\`\`\`

## Prompt
\`\`\`
User prompt to test
\`\`\`

## Expected Behavior
- Should do X
- Should mention Y
- Should include Z

## Validation Checkpoints
- [ ] Checkpoint 1
- [ ] Checkpoint 2
- [ ] Checkpoint 3

## Example Output
\`\`\`
Expected AI response...
\`\`\`
```

## Continuous Testing

For plugin development:

```bash
# Watch for changes and re-run tests
watch -n 5 './test-harness/run-tests.sh'

# Or use file watcher
fswatch -o . | xargs -n1 ./test-harness/run-tests.sh
```

## Test Results

Results are saved to `test-harness/results/`:
- `YYYY-MM-DD-HH-MM-SS-results.json` - Test run results
- `latest.json` - Symlink to latest results
- `summary.txt` - Human-readable summary

## Troubleshooting

**Plugin not loading:**
- Check `~/.claude/plugins/convex/` exists
- Verify `.cursor/plugin.json` is valid
- Restart Claude Code

**Tests failing:**
- Check you're in a test project directory
- Verify plugin is installed correctly
- Review test scenario for correct setup

**Rules not applying:**
- Ensure test files match glob patterns
- Check rule `alwaysApply` is true
- Verify you're editing files in `convex/` directory

## Success Metrics

Plugin passes tests if:
- ✅ 90%+ of proactive recommendations trigger correctly
- ✅ 100% of generated code includes validators
- ✅ 100% of generated code includes auth checks
- ✅ 100% of schemas use proper indexes
- ✅ 100% of responses emphasize "convex dev"
- ✅ 100% of auth examples show WorkOS first

## Contributing

To add new test scenarios:
1. Create scenario file in `scenarios/`
2. Add expected output in `expected-outputs/`
3. Update this README
4. Run tests and verify
5. Submit PR with test results
