# Contributing to Convex Agent Plugins

Thank you for your interest in contributing to the official Convex plugins for AI coding agents!

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in [GitHub Issues](https://github.com/get-convex/convex-agent-plugins/issues)
2. If not, create a new issue with:
   - Clear description of the problem or suggestion
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your IDE/agent (Cursor, Claude Code, etc.) and Convex versions

### Suggesting Rules or Skills

Have an idea for a new rule or skill?

1. **For Rules**: Identify a common Convex pattern or pitfall
   - Should be actionable and specific
   - Must apply broadly to Convex development
   - Should include clear examples

2. **For Skills**: Identify a complex, repetitive Convex task
   - Should require specialized knowledge
   - Must be reusable across projects
   - Should include step-by-step guidance

Open an issue with your proposal before creating a PR.

### Code Contributions

1. **Fork the repository**

2. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing file structure
   - Use clear, descriptive names
   - Include examples in documentation

4. **Test your changes**
   - Install the plugin locally in your IDE/agent
   - Test all components work as expected
   - Verify rules activate correctly
   - Test skills with real scenarios

5. **Commit with clear messages**
   ```bash
   git commit -m "Add rule for cron job scheduling patterns"
   ```

6. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Development Guidelines

### Writing Rules

Rules should:
- Have descriptive frontmatter (description, alwaysApply, globs)
- Include both good and bad examples
- Explain *why* the rule matters
- Be concise but comprehensive

Example structure:
```markdown
---
description: Brief description of the rule
alwaysApply: true
globs: ["convex/**/*.ts"]
---

# Rule Title

Explanation of the pattern or anti-pattern.

## Why This Matters

Explain the consequences of not following the rule.

## Examples

**Bad:**
\`\`\`typescript
// Anti-pattern
\`\`\`

**Good:**
\`\`\`typescript
// Correct pattern
\`\`\`
```

### Writing Skills

Skills should:
- Have clear frontmatter (name, description)
- Define when to use the skill
- Provide templates and patterns
- Include complete, working examples
- Have a checklist for completion

Example structure:
```markdown
---
name: skill-name
description: When and why to use this skill
---

# Skill Title

Overview of what this skill does.

## When to Use

- Specific scenario 1
- Specific scenario 2

## Pattern/Template

\`\`\`typescript
// Working code template
\`\`\`

## Examples

Complete, copy-pasteable examples.

## Checklist

- [ ] Item 1
- [ ] Item 2
```

### Writing Agents

Agents should:
- Have clear frontmatter (name, description)
- Define their specialized role
- Provide systematic review or creation steps
- Include common patterns to look for

### Hook Scripts

Hook scripts should:
- Be POSIX-compliant shell scripts
- Exit 0 for warnings (don't block)
- Exit 1 for errors (block action)
- Provide clear, actionable messages
- Be fast (< 1 second for common cases)

## Testing

Before submitting:

1. **Local Installation Test**
   ```bash
   # For Cursor
   cp -r . ~/.cursor/plugins/convex

   # For Claude Code
   ln -s $(pwd) ~/.claude/plugins/convex
   ```

2. **Rule Test**
   - Create a test Convex project
   - Write code that triggers each rule
   - Verify AI suggests corrections

3. **Skill Test**
   - Invoke each skill in your IDE/agent
   - Verify it produces correct output
   - Check examples are accurate

4. **Hook Test**
   - Create files matching hook patterns
   - Verify hooks trigger correctly
   - Check error messages are clear

## Documentation

All contributions should include:

- Updates to README.md if adding features
- Comments in code for complex logic
- Examples demonstrating usage
- Frontmatter with proper metadata

## Community

- Join the [Convex Discord](https://convex.dev/community)
- Ask questions in #convex-agent-plugins channel
- Share your contributions and get feedback

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn Convex patterns
- Celebrate good contributions

## Questions?

- Discord: [convex.dev/community](https://convex.dev/community)
- Email: support@convex.dev
- GitHub Issues: Report bugs or suggestions

Thank you for helping make Convex development with AI agents even better! 🎉
