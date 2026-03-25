---
name: baoyu-translate-output-manager
description: Manage translated document naming and placement after using baoyu-translate. Use this skill whenever the user asks to translate a file and wants translated output saved next to the source file, with filename clearly indicating source relationship and target language. This skill focuses on file creation/location management and must not replace or alter baoyu-translate translation quality workflow.
version: 0.1.0
---

# Baoyu Translate Output Manager

This skill exists to prevent two common problems:

1. Editing the original source file directly during translation
2. Saving translated files to unrelated directories

It is a wrapper for output file management. Translation quality and translation method should continue to follow `../baoyu-translate/SKILL.md`.

## Scope

Do:
- Resolve source file path
- Infer or confirm target language
- Create translated file in the same directory as source
- Apply deterministic filename convention
- Keep source file unchanged

Do not:
- Replace the translation logic from `baoyu-translate`
- Introduce extra style constraints that could affect translation quality
- Move translated file to a different directory unless user explicitly requests it

## Core Principle

Treat `baoyu-translate` as the translation engine, and this skill as the output policy layer.

## Required Workflow

1. Read and follow `../baoyu-translate/SKILL.md` for translation generation.
2. Before writing output, compute target filename with the naming convention below.
3. Write translated content to the target filename in the same directory as source.
4. Verify source file content was not overwritten.
5. Report both source path and translated path to user.

## Naming Convention

Translated file must be in source file's directory and use:

`<source-basename>.translated.<target-lang><source-ext>`

Examples:
- `guide.md` -> `guide.translated.zh-CN.md`
- `README.en.md` -> `README.en.translated.zh-CN.md`
- `api-reference.txt` -> `api-reference.translated.ja.txt`

If target language is unknown, ask user before writing:
- "目标语言要用什么标识？例如 zh-CN / en / ja"

## Language Tag Rules

- Prefer explicit user input
- Else use `baoyu-translate` resolved target language
- Keep BCP-47 style when available (e.g., `zh-CN`, `en-US`)
- Preserve exact case of region (e.g., `zh-CN`, not `zh-cn`)

## Safety Rules

- Never overwrite source file
- Never silently overwrite an existing translated file
- If target file exists, append timestamp suffix:
  - `<source-basename>.translated.<target-lang>.<YYYYMMDD-HHmmss><source-ext>`

Example:
- `guide.translated.zh-CN.20260324-153045.md`

## Output Summary Template

Use this concise report:

```text
Translation output created
- Source: <source-file>
- Target language: <target-lang>
- New file: <translated-file>
- Placement: same directory as source
- Source unchanged: yes
```

## Notes For Accuracy Protection

- Do not rewrite or simplify `baoyu-translate` translation steps.
- Do not inject extra rewriting instructions unrelated to file naming/placement.
- If there is any conflict, prefer `baoyu-translate` for translation quality and this skill for final file naming/location only.
