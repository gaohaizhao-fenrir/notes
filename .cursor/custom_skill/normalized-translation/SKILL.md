---
name: normalized-translation
description: 用于规范化翻译执行边界的薄包装 Skill。凡是用户要求“翻译文档/文章/Markdown/说明书”，或要求“统一术语、固定规范、不要覆盖原文”时触发。该 Skill 不重定义翻译策略，只负责强制委托给 baoyu-translate，并约束配置来源、输入边界与输出路径。
---

# Normalized Translation

该 Skill 是“最小包装层”。目标只有三件事：
1) 委托翻译给 `baoyu-translate`  
2) 固定 EXTEND 配置来源  
3) 保证输出不覆盖原文

## 适用场景

当用户有以下意图时触发：

- “把这篇文档翻译成中文/英文”
- “按固定规范翻译”
- “术语统一、风格一致”
- “翻译后不要覆盖原文”
- “参考 baoyu-translate 做翻译”

## 核心原则（必须）

### 1) 单一翻译规范来源

任何翻译任务都 **必须先读取并遵循**：

- `@.agents/skills/baoyu-translate/SKILL.md`

本 Skill **不重复定义** 翻译原则、模式、工作流、术语策略、润色规则，全部以 `baoyu-translate` 为准，避免提示词冲突。

### 2) 单一配置来源

EXTEND 配置固定为：

- `@.baoyu-skills/baoyu-translate/EXTEND.md`

若该文件不存在或不可读：必须中止并提示用户修复，禁止静默回退到其他配置。

### 3) 输入边界

当用户已明确指定翻译目标文件，且未授权额外上下文时：

- 翻译语料仅限该目标文件
- 不读取无关业务文件辅助翻译
- 尤其不读取同目录下相似产物（历史译稿、同名变体、缓存文件等）
- `references/` 与 `scripts/` 若由 `baoyu-translate` 工作流直接引用，视为规范组成部分，可正常读取与执行

用户后续若明确授权补充上下文，再按授权范围读取。

### 4) 输出策略（不覆盖）

默认输出到“源文件同目录新文件”，不得覆盖原文。

- 源文件：`/path/to/doc.md`
- 默认译文：`/path/to/doc_zh-CN.md`（语言后缀取自 `target_language`）

若目标文件已存在，自动递增版本号，例如：
- `doc_zh-CN.v2.md`
- `doc_zh-CN.v3.md`

仅在用户明确要求覆盖时才允许覆盖。

## 执行前最小检查

开始翻译前必须满足：

1. 已读取 `@.agents/skills/baoyu-translate/SKILL.md`
2. 已读取 `@.baoyu-skills/baoyu-translate/EXTEND.md`
3. 已确认输出为“同目录新文件”
5. 已确认不会覆盖源文件
6. 已确认未读取无关业务文件（用户明确授权除外）

任一项不满足时，不得开始翻译。

## 文件命名约定

- Markdown：`<basename>_<target_language>.md`
- 纯文本：`<basename>_<target_language>.txt`
- 其他格式：保持原扩展名，语言后缀放在扩展名前
  - 例如：`guide.pdf` -> `guide_zh-CN.pdf`

## 回复模板

完成后用简洁模板回复：

```text
翻译完成（normalized-translation）

Source: <source-path>
Delegate: .agents/skills/baoyu-translate/SKILL.md
Config: .baoyu-skills/baoyu-translate/EXTEND.md
Mode: <mode>
Audience: <audience>
Style: <style>
Output: <output-path>
```
