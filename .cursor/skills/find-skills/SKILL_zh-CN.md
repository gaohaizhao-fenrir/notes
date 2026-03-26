---
name: find-skills
description: 当用户询问“如何做 X”“帮我找个做 X 的 skill”“有没有能做 X 的 skill”，或表达希望扩展能力时，帮助用户发现并安装 agent skills。该 skill 适用于用户寻找可能以可安装 skill 形式存在的功能。
---

# 查找 Skills

该 skill 用于从开放的 agent skills 生态中发现并安装合适的技能。

## 何时使用本 Skill

当用户出现以下意图时，使用本 skill：

- 询问“如何做 X”，且 X 可能是已有 skill 覆盖的常见任务
- 说“帮我找个做 X 的 skill”或“有没有 X 的 skill”
- 询问“你能做 X 吗”，且 X 属于某类专业能力
- 表达希望扩展 agent 能力
- 想搜索工具、模板或工作流
- 提到希望在某个特定领域（设计、测试、部署等）获得帮助

## Skills CLI 是什么？

Skills CLI（`npx skills`）是开放 agent skills 生态的包管理工具。Skills 是模块化包，可通过专门知识、工作流和工具扩展 agent 能力。

**关键命令：**

- `npx skills find [query]` - 交互式或按关键词搜索 skills
- `npx skills add <package>` - 从 GitHub 或其他来源安装 skill
- `npx skills check` - 检查 skill 更新
- `npx skills update` - 更新所有已安装 skills

**浏览 skills：** https://skills.sh/

## 如何帮助用户查找 Skills

### 步骤 1：明确用户需求

当用户请求帮助时，识别：

1. 领域（例如 React、测试、设计、部署）
2. 具体任务（例如写测试、做动画、评审 PR）
3. 该任务是否足够常见，因而很可能已有 skill

### 步骤 2：先看排行榜

在运行 CLI 搜索前，先查看 [skills.sh 排行榜](https://skills.sh/)，确认目标领域是否已有知名 skill。排行榜按总安装量排序，可优先暴露更热门、经过验证的选项。

例如，Web 开发领域的头部 skills 包括：
- `vercel-labs/agent-skills` — React、Next.js、Web 设计（各 100K+ 安装）
- `anthropics/skills` — 前端设计、文档处理（100K+ 安装）

### 步骤 3：搜索 Skills

如果排行榜无法覆盖用户需求，运行查找命令：

```bash
npx skills find [query]
```

例如：

- 用户问“怎么让我的 React 应用更快？” -> `npx skills find react performance`
- 用户问“你能帮我做 PR review 吗？” -> `npx skills find pr review`
- 用户说“我需要生成 changelog” -> `npx skills find changelog`

### 步骤 4：推荐前先验证质量

**不要仅凭搜索结果推荐 skill。** 必须验证：

1. **安装量** — 优先选择 1K+ 安装的 skill；低于 100 的需谨慎。
2. **来源信誉** — 官方来源（`vercel-labs`、`anthropics`、`microsoft`）通常比未知作者更可信。
3. **GitHub stars** — 检查源仓库；来自少于 100 stars 仓库的 skill 需保持怀疑。

### 步骤 5：向用户展示选项

找到相关 skills 后，向用户提供：

1. skill 名称及其作用
2. 安装量与来源
3. 可执行的安装命令
4. 指向 skills.sh 的详情链接

回复示例：

```
我找到一个可能有帮助的 skill！“react-best-practices” 提供来自 Vercel Engineering 的
React 和 Next.js 性能优化指南。
（185K 安装）

安装命令：
npx skills add vercel-labs/agent-skills@react-best-practices

了解更多：https://skills.sh/vercel-labs/agent-skills/react-best-practices
```

### 步骤 6：提供代安装

如果用户希望继续，你可以代为安装：

```bash
npx skills add <owner/repo@skill> -g -y
```

`-g` 表示全局安装（用户级），`-y` 表示跳过确认提示。

## 常见 Skill 分类

搜索时可优先考虑以下常见类别：

| 分类 | 示例查询 |
| --- | --- |
| Web 开发 | react, nextjs, typescript, css, tailwind |
| 测试 | testing, jest, playwright, e2e |
| DevOps | deploy, docker, kubernetes, ci-cd |
| 文档 | docs, readme, changelog, api-docs |
| 代码质量 | review, lint, refactor, best-practices |
| 设计 | ui, ux, design-system, accessibility |
| 效率提升 | workflow, automation, git |

## 提高搜索效果的技巧

1. **使用更具体的关键词**：“react testing” 比单独 “testing” 更好。
2. **尝试近义词**：如果 “deploy” 结果不理想，试试 “deployment” 或 “ci-cd”。
3. **检查热门来源**：许多 skills 来自 `vercel-labs/agent-skills` 或 `ComposioHQ/awesome-claude-skills`。

## 找不到 Skills 时

如果没有相关 skill：

1. 明确告知未找到现成 skill
2. 提供直接使用通用能力协助完成任务
3. 建议用户使用 `npx skills init` 创建自己的 skill

示例：

```
我搜索了与 “xyz” 相关的 skills，但没有找到匹配结果。
我仍然可以直接帮你完成这个任务！要我继续吗？

如果这是你经常做的事，可以创建一个自己的 skill：
npx skills init my-xyz-skill
```
---
name: find-skills
description: 当用户提出“我该怎么做 X”“帮我找一个做 X 的 skill”“有没有能做 X 的 skill”这类问题，或表达希望扩展能力时，帮助用户发现并安装 agent skills。该 skill 适用于用户正在寻找可能以可安装 skill 形式存在的功能。
---

# 查找 Skills

这个 skill 用于帮助你在开放的 agent skills 生态中发现并安装 skills。

## 何时使用这个 Skill

当用户出现以下意图时，使用此 skill：

- 询问“我该怎么做 X”，且 X 可能是已有 skill 覆盖的常见任务
- 提到“帮我找一个做 X 的 skill”或“有没有做 X 的 skill”
- 询问“你能做 X 吗”，其中 X 属于专项能力
- 表达希望扩展 agent 能力
- 想搜索工具、模板或工作流
- 提到希望在某个具体领域获得帮助（设计、测试、部署等）

## 什么是 Skills CLI？

Skills CLI（`npx skills`）是开放 agent skills 生态的包管理器。Skill 是模块化包，可通过专业知识、工作流与工具扩展 agent 能力。

**核心命令：**

- `npx skills find [query]` - 交互式或按关键词搜索 skills
- `npx skills add <package>` - 从 GitHub 或其他来源安装 skill
- `npx skills check` - 检查 skill 更新
- `npx skills update` - 更新所有已安装 skills

**浏览 skills：** https://skills.sh/

## 如何帮助用户查找 Skills

### 第 1 步：理解用户需求

当用户请求帮助时，先识别：

1. 领域（例如 React、测试、设计、部署）
2. 具体任务（例如写测试、做动画、评审 PR）
3. 该任务是否足够常见，以至于很可能已有对应 skill

### 第 2 步：先看排行榜

在运行 CLI 搜索前，先查看 [skills.sh 排行榜](https://skills.sh/)，确认该领域是否已有知名 skill。排行榜按总安装量排序，能优先呈现最流行、经过验证的选项。

例如，Web 开发领域的头部 skills 包括：
- `vercel-labs/agent-skills` — React、Next.js、Web 设计（各 10 万+ 安装）
- `anthropics/skills` — 前端设计、文档处理（10 万+ 安装）

### 第 3 步：搜索 Skills

如果排行榜未覆盖用户需求，运行以下查找命令：

```bash
npx skills find [query]
```

例如：

- 用户问“怎么让我的 React 应用更快？” → `npx skills find react performance`
- 用户问“你能帮我做 PR review 吗？” → `npx skills find pr review`
- 用户说“我需要生成 changelog” → `npx skills find changelog`

### 第 4 步：推荐前先验证质量

**不要仅凭搜索结果就推荐某个 skill。** 始终验证：

1. **安装量** — 优先选择 1K+ 安装；低于 100 需谨慎。
2. **来源信誉** — 官方来源（`vercel-labs`、`anthropics`、`microsoft`）通常比未知作者更可信。
3. **GitHub stars** — 检查来源仓库；若仓库星标 <100，应保持怀疑。

### 第 5 步：向用户呈现可选项

找到相关 skills 后，向用户提供：

1. Skill 名称及功能说明
2. 安装量与来源
3. 可执行的安装命令
4. `skills.sh` 上的详情链接

示例回复：

```
我找到了一个可能有帮助的 skill！“react-best-practices” 提供了
来自 Vercel Engineering 的 React 和 Next.js 性能优化指南。
（185K 安装）

安装命令：
npx skills add vercel-labs/agent-skills@react-best-practices

了解更多：https://skills.sh/vercel-labs/agent-skills/react-best-practices
```

### 第 6 步：主动提供安装

如果用户希望继续，你可以直接帮他安装 skill：

```bash
npx skills add <owner/repo@skill> -g -y
```

其中 `-g` 表示全局安装（用户级），`-y` 表示跳过确认提示。

## 常见 Skill 分类

搜索时可优先考虑以下常见分类：

| 分类 | 示例查询 |
| --------------- | ---------------------------------------- |
| Web 开发 | react, nextjs, typescript, css, tailwind |
| 测试 | testing, jest, playwright, e2e |
| DevOps | deploy, docker, kubernetes, ci-cd |
| 文档 | docs, readme, changelog, api-docs |
| 代码质量 | review, lint, refactor, best-practices |
| 设计 | ui, ux, design-system, accessibility |
| 生产力 | workflow, automation, git |

## 提升搜索效果的技巧

1. **使用更具体关键词**：`react testing` 比单独 `testing` 更好
2. **尝试同义词**：如果 `deploy` 效果不好，试试 `deployment` 或 `ci-cd`
3. **关注热门来源**：很多 skills 来自 `vercel-labs/agent-skills` 或 `ComposioHQ/awesome-claude-skills`

## 当没有找到相关 Skills 时

如果没有匹配 skill：

1. 明确告知暂未找到现成 skill
2. 提供直接用通用能力完成任务的方案
3. 建议用户用 `npx skills init` 自建 skill

示例：

```
我搜索了与“xyz”相关的 skills，但目前没有找到匹配项。
我依然可以直接帮你完成这个任务！要我继续吗？

如果这是你经常做的事情，你也可以创建自己的 skill：
npx skills init my-xyz-skill
```
