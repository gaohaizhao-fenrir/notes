---
name: translation-docs-directory-management
description: Manages multilingual documentation directory structure, naming conventions, and update workflow for translated docs. Use when users ask to add translated documents, organize translation folders, or keep source and translation docs consistent.
---

# Translation Docs Directory Management

## Purpose

Use this skill to keep translated documentation organized and predictable when adding or updating documents across languages.

## When To Apply

Apply this skill when the user asks to:
- add a new translated document
- organize or refactor translation directories
- define naming/path conventions for docs
- keep translation folders aligned with source docs
- "翻译某某文档" and place it in the correct location

## Standard Directory Rules

Use these defaults unless the user provides project-specific rules:

- Source language root: `docs/zh-CN/`
- Target language root: `docs/en-US/`
- Same relative path for source and translation files
- Same filename stem across languages
- Markdown docs use `.md` extension

Example path mapping:
- source: `docs/zh-CN/guides/setup.md`
- target: `docs/en-US/guides/setup.md`

## Naming Conventions

- Use lowercase letters, numbers, and hyphens in file names
- Avoid spaces and mixed separators
- Keep directory names semantically consistent across languages
- Keep one concept per file; avoid overly broad "misc" files

## Workflow For New Translation Doc

1. Identify source file path and language.
2. Derive target path by replacing only the language root.
3. If target directories are missing, create them.
4. Create translation file at the mapped target path.
5. Record status with a short report using the template below.

## Template Output (Required)

Always return results in this format:

```markdown
# Translation Directory Update

## Request
- Source file: <source-path>
- Target language: <target-lang>

## Path Mapping
- Source: <source-path>
- Target: <target-path>

## Actions
- [ ] Verified source exists
- [ ] Verified naming convention
- [ ] Created missing directories (if needed)
- [ ] Created/updated target file

## Notes
- <any risks, assumptions, or follow-up work>
```

## Conflict Handling

If project rules conflict with this skill:
- follow explicit project conventions first
- keep language root replacement logic unchanged
- explain any overridden rule in `Notes`

## Quality Checklist

Before finishing, confirm:
- source and target paths are structurally aligned
- naming conventions are satisfied
- no accidental path drift between languages
