---
name: manage-skills
description: Create, edit, or manage Claude/Cursor AI skills. Use when the user wants to add, update, or remove skills or Claude instructions.
---

# Managing AI Skills

Skills live in the dotfiles repo at `~/Development/dotfiles/configs/ai/skills/`. Each `.md` file in that directory becomes a skill.

## Two Formats

### Always-on (no frontmatter)

Content is injected directly into `~/.claude/CLAUDE.md` and always included in context. Use for coding standards, style guides, and rules that should always apply.

```markdown
# Code Style

- Prefer simple, readable code over clever abstractions
- Use descriptive variable and function names
```

### Command skill (YAML frontmatter)

Becomes an invokable `/msilvis:<name>` command in Claude Code and a manual rule in Cursor. Use for task-specific workflows.

```markdown
---
name: my-skill
description: Short description of when to use this skill.
---

# My Skill

Instructions go here...
```

## Workflow

1. Create or edit a `.md` file in `~/Development/dotfiles/configs/ai/skills/`
2. Run `dotfiles-sync` to install changes

The sync writes:
- Always-on skills into `~/.claude/CLAUDE.md` (and `~/.cursor/rules/`)
- Command skills into `~/.claude/commands/msilvis:<name>.md` (and `~/.cursor/rules/`)

## Guidelines

- Keep skill names lowercase and hyphenated (e.g., `my-skill.md`)
- Write clear descriptions in frontmatter so Claude knows when to invoke the command
- Keep always-on skills concise since they consume context in every conversation
- Prefer command skills for task-specific workflows that don't need to be always active
