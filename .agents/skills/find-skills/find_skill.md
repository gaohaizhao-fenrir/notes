---
name: find-skills
description: 当用户询问“如何做 X”“找一个做 X 的 skill”“有没有能做 X 的 skill”，或表达希望扩展能力时，帮助用户发现并安装 agent skills。该 skill 适用于用户在寻找可能以可安装 skill 形式提供的功能。
---

# 查找 Skills

该 skill 用于帮助你从开放的 agent skills 生态中发现并安装技能。

## 何时使用此 Skill

当用户出现以下情况时，使用该 skill：

- 询问“如何做 X”，且 X 可能是已有 skill 覆盖的常见任务
- 说“找个做 X 的 skill”或“有没有做 X 的 skill”
- 询问“你能做 X 吗”，且 X 属于专业化能力
- 表达希望扩展 agent 能力
- 希望搜索工具、模板或工作流
- 提到希望在特定领域（设计、测试、部署等）获得帮助

## Skills CLI 是什么？

Skills CLI（`npx skills`）是开放 agent skills 生态的包管理器。Skill 是模块化包，通过专门知识、工作流与工具扩展 agent 能力。

**关键命令：**

- `npx skills find [query]` - 交互式或按关键词搜索 skills
- `npx skills add <package>` - 从 GitHub 或其他来源安装 skill
- `npx skills check` - 检查 skill 更新
- `npx skills update` - 更新全部已安装 skills

**浏览 skills：** https://skills.sh/

## 如何帮助用户查找 Skills

### 步骤 1：理解用户需求

当用户请求帮助时，识别：

1. 领域（例如 React、测试、设计、部署）
2. 具体任务（例如写测试、制作动画、评审 PR）
3. 任务是否足够常见，从而很可能已有现成 skill

### 步骤 2：先看排行榜

在运行 CLI 搜索之前，先查看 [skills.sh 排行榜](https://skills.sh/)，确认目标领域是否已有知名 skill。排行榜按总安装量排序，能优先展示最流行、经过实战检验的选项。

例如，Web 开发领域的头部 skills 包括：
- `vercel-labs/agent-skills` — React、Next.js、网页设计（每项 100K+ 安装）
- `anthropics/skills` — 前端设计、文档处理（100K+ 安装）

### 步骤 3：搜索 Skills

如果排行榜未覆盖用户需求，执行查找命令：

```bash
npx skills find [query]
```

例如：

- 用户问“如何让我的 React 应用更快？” -> `npx skills find react performance`
- 用户问“你能帮我做 PR 审查吗？” -> `npx skills find pr review`
- 用户说“我需要生成 changelog” -> `npx skills find changelog`

### 步骤 4：推荐前验证质量

**不要仅凭搜索结果推荐 skill。** 必须始终验证：

1. **安装量** — 优先 1K+ 安装；低于 100 的需谨慎。
2. **来源信誉** — 官方来源（`vercel-labs`、`anthropics`、`microsoft`）通常比未知作者更可信。
3. **GitHub stars** — 检查源仓库；若仓库少于 100 stars，需保持怀疑态度。

### 步骤 5：向用户呈现选项

找到相关 skills 后，向用户提供：

1. skill 名称及作用
2. 安装量与来源
3. 可执行的安装命令
4. skills.sh 详情链接

回复示例：

```
我找到一个可能有帮助的 skill！"react-best-practices" 提供
Vercel Engineering 出品的 React 和 Next.js 性能优化指南。
（185K 安装）

安装方式：
npx skills add vercel-labs/agent-skills@react-best-practices

了解更多：https://skills.sh/vercel-labs/agent-skills/react-best-practices
```

### 步骤 6：提供安装协助

如果用户希望继续，你可以为其安装该 skill：

```bash
npx skills add <owner/repo@skill> -g -y
```

`-g` 表示全局安装（用户级），`-y` 表示跳过确认提示。

## 常见 Skill 分类

搜索时可优先考虑以下常见类别：

| Category | 示例查询 |
| -------- | -------- |
| Web Development | react, nextjs, typescript, css, tailwind |
| Testing | testing, jest, playwright, e2e |
| DevOps | deploy, docker, kubernetes, ci-cd |
| Documentation | docs, readme, changelog, api-docs |
| Code Quality | review, lint, refactor, best-practices |
| Design | ui, ux, design-system, accessibility |
| Productivity | workflow, automation, git |

## 提升搜索效果的技巧

1. **使用具体关键词**："react testing" 比仅用 "testing" 更好
2. **尝试替代术语**：若 "deploy" 结果不理想，尝试 "deployment" 或 "ci-cd"
3. **关注热门来源**：很多 skills 来自 `vercel-labs/agent-skills` 或 `ComposioHQ/awesome-claude-skills`

## 当找不到 Skills 时

如果不存在相关 skill：

1. 明确告知未找到现成 skill
2. 提供直接使用通用能力完成任务的帮助
3. 建议用户通过 `npx skills init` 创建自定义 skill

示例：

```
我搜索了与 "xyz" 相关的 skills，但没有找到匹配项。
我仍然可以直接帮你完成这个任务！要我继续吗？

如果这是你经常做的事情，可以创建自己的 skill：
npx skills init my-xyz-skill
```
