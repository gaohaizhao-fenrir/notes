# ADK Agent 技能五种设计模式（译文与要点总结）

**原文**：[5 Agent Skill Design Patterns Every ADK Developer Should Know](https://lavinigam.com/posts/adk-skill-design-patterns/)（Lavi Nigam）  
**说明**：本文是对上述博文的**技术向中文总结**，保留核心概念、结构与选型依据；示例代码与英文原文细节请参阅原帖及 [示例仓库](https://github.com/lavinigam-gcp/build-with-adk/tree/main/adk-skill-design-patterns)。

---

## 1. 背景：同一种 SKILL.md，不同的「内容设计」

[Agent Skills 规范](https://agentskills.io/specification)规定了技能容器的形态（YAML frontmatter、`references/`、`assets/`、`scripts/`），但**不规定** SKILL.md 内部应写成清单、工作流还是问答。  
因此需要**可复用的内容结构模式**：同一目录布局下，用不同方式组织 L2（指令）与 L3（参考资料/资源）的关系。

作者在 Claude Code 内置技能、[skills.sh](https://skills.sh/) 社区、实际项目以及 [arXiv: SoK: Agentic Skills（2026-02）](https://arxiv.org/html/2602.20867v1) 等来源中归纳出**五种最实用**的模式，并在 Google ADK 中给出可运行示例。

**系列延伸**：[ADK Skills 三部曲](https://lavinigam.com/posts/adk-agent-skills-part1/)（渐进披露、SkillToolset 内部、自扩展元技能）；官方 [ADK Core Skills](https://google.github.io/adk-docs/tutorials/coding-with-ai/)。

---

## 2. 标准目录（所有兼容 Agent Skills 的工具通用）

```
skill-name/
├── SKILL.md          # YAML frontmatter + Markdown 指令（必填）
├── references/       # 风格指南、清单、约定（可选）
├── assets/           # 模板与输出形态（可选）
└── scripts/          # 可执行脚本（可选）
```

已被 [30+ agent 工具](https://agentskills.io/home)采用（含 Claude Code、Gemini CLI、GitHub Copilot、Cursor 等）。

---

## 3. SkillToolset 与三层渐进披露（简述）

ADK 的 [SkillToolset](https://google.github.io/adk-docs/skills/) 通过三个自动生成的工具实现渐进披露：

| 层级 | 工具 | 作用 |
|------|------|------|
| L1 | `list_skills` | 技能名与描述（约每技能 ~100 token 级开销） |
| L2 | `load_skill` | 拉取完整 SKILL.md 指令 |
| L3 | `load_skill_resource` | 按需加载参考文件与模板 |

代理仅在需要时加载更深内容，控制上下文成本。文中五个示例技能可装入**同一个** `SkillToolset`，由用户请求决定激活哪一个。

**关键实践**：每个技能 frontmatter 里的 **`description` 是「检索索引」**——必须包含用户会真实输入的关键词；描述含糊（如「帮助处理 API」）会导致技能难以被选中。

---

## 4. 五种模式概览

| 模式 | 一句话 | 典型目录 |
|------|--------|----------|
| **Tool Wrapper（工具封装）** | 把库/工具的约定与最佳实践打包成按需加载的专家知识 | 主要 `references/` |
| **Generator（生成器）** | 用模板 + 风格规则产出结构固定、每次一致的文档/配置 | `assets/` + `references/` |
| **Reviewer（评审）** | 按 `references/` 中的清单检查，输出按严重度分组的结果 | `references/` |
| **Inversion（反转）** | 代理在产出前先分阶段提问，凑齐信息再合成 | 常配合 `assets/` 中的输出模板 |
| **Pipeline（流水线）** | 严格顺序步骤 + 显式门禁（如用户确认），防止跳步 | `references/` + `assets/` + `scripts/` |

五种模式**可组合**：例如 Pipeline 某步嵌入 Reviewer；Generator 前用 Inversion 收集输入。

---

## 5. Pattern 1：Tool Wrapper —— 教代理「会用某个库」

- **定义**：将框架/库的约定、实践、编码标准写入技能；激活时代理表现为该领域的「专家」。  
- **结构**：最简单——**只有指令 + `references/`，通常无模板与脚本**。详细规则放在 `references/conventions.md` 等文件中，按需加载。  
- **description 写法**：包含具体技术名（如 FastAPI、REST、Pydantic），避免空泛描述。  
- **metadata**：ADK 中 `metadata` 为 `dict[str, str]`，无强制 schema；可用 `pattern`、`domain` 等标签便于大量技能时审计。

**公开范例**：Vercel `react-best-practices`、Supabase `supabase-postgres-best-practices`、Google `gemini-api-dev`、Google [adk-core-skills](https://github.com/google/adk-docs/tree/main/skills)（可通过 `npx skills add google/adk-docs -y -g` 安装到各类 coding agent）。  
**内部用法**：例如团队 `google-adk-conventions`，统一默认模型、代理命名、Toolset 接线与错误处理，避免在每个 system prompt 里重复。

---

## 6. Pattern 2：Generator —— 产出结构化输出

- **定义**：用**可复用模板**生成报告、文档或配置。  
- **分工**：`assets/` 放**输出结构**（要填的章节）；`references/` 放**质量规则**（语气、格式、字数等）。指令负责编排：先风格、再模板、再补全缺失输入、最后填满并返回。  
- **优势**：更换模板或风格文件即可改变产出，**不必改核心指令**。

**适用**：固定章节的技术报告、统一结构的 API 文档、Conventional Commits 式提交信息、ADK 项目脚手架（`agent.py` + `__init__.py` + `.env` 等）。

---

## 7. Pattern 3：Reviewer —— 对照标准打分/列问题

- **核心设计**：**检查项（WHAT）** 放在 `references/review-checklist.md` 等文件；**评审协议（HOW）** 写在 SKILL.md。替换清单即可在同一结构下做安全审计、编辑规范检查等不同任务。  
- **输出**：通常含摘要、按严重度（error / warning / info）分组的问题、评分与优先建议。

**适用**：代码审查、OWASP 类安全扫描、文档/博客是否符合编辑部规范、新 ADK agent 是否符合团队 `google-adk-conventions`。

---

## 8. Pattern 4：Inversion —— 技能先「访谈」用户

- **定义**：反转常见交互——由技能驱动**分阶段提问**，凑齐信息后再生成结果；依赖明确门禁句（如「在完成所有阶段前不要开始搭建/设计」），**不依赖**额外框架特性。  
- **要点**：阶段必须顺序完成；合成阶段可加载 `assets/plan-template.md` 等锚定输出结构。

**适用**：需求采集、结构化排障问卷、部署/配置向导、设计新 ADK agent 前的工具与模型选型访谈。

---

## 9. Pattern 5：Pipeline —— 多步工作流与门禁

- **定义**：步骤**严格顺序**执行；用「本步失败则勿继续」「未经用户确认勿进入下一步」等**门控**避免代理一口气跳过校验。  
- **复杂度**：通常最高，可同时使用 `references/`、`assets/`、`scripts/`，指令本身即工作流定义。每步只加载当前需要的资源，节省 token。

**适用**：文档生成（解析 → 生成 docstring 并确认 → 汇编 → 质检）、数据处理链、带人工确认的发布流程；也可组合 Inversion + Generator + Reviewer 形成「入职式」流水线。

---

## 10. 如何选型

| 模式 | 适用场景 | 主要使用目录 | 复杂度 |
|------|----------|--------------|--------|
| Tool Wrapper | 需要针对某库/工具的专家级约定 | `references/` | 低 |
| Generator | 输出必须每次遵循同一套结构 | `assets/` + `references/` | 中 |
| Reviewer | 需按清单评估代码或内容 | `references/` | 中 |
| Inversion | 必须先向用户收集上下文再行动 | `assets/`（常含模板） | 中（多轮） |
| Pipeline | 有序步骤且步骤间需校验/确认 | 三者皆可 | 高 |

**组合**：生产系统常见 **2～3 种模式叠加**；文献中最常见组合之一是**元数据驱动的披露（接近 Tool Wrapper）+ 分发/市场机制**。

原帖文末附有**决策树图示**（yes/no 分支），可辅助在模糊场景下定类。

---

## 11. 生态简述

符合 Agent Skills 标准的技能可通过 `load_skill_from_dir()` 在 ADK 中加载；社区可从 [skills.sh](https://skills.sh/) 等来源浏览与安装技能。不必一切从零编写——与 Claude Code、Gemini CLI、Cursor 等共用的技能包可直接复用到 ADK。

---

## 12. 原文与代码

- **博客**：[lavinigam.com — ADK Skill Design Patterns](https://lavinigam.com/posts/adk-skill-design-patterns/)  
- **代码**：[github.com/lavinigam-gcp/build-with-adk — adk-skill-design-patterns](https://github.com/lavinigam-gcp/build-with-adk/tree/main/adk-skill-design-patterns)

---

*文档生成说明：目标语言 zh-CN；受众为开发者；风格为技术文档体（与 `.baoyu-skills/baoyu-translate/EXTEND.md` 中 `technical` 一致）。*
