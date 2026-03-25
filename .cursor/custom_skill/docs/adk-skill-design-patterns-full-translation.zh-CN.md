# 每位 ADK 开发者都应了解的五种 Agent 技能设计模式（全文译）

**原文标题**：5 Agent Skill Design Patterns Every ADK Developer Should Know  
**作者**：Lavi Nigam  
**来源**：[https://lavinigam.com/posts/adk-skill-design-patterns/](https://lavinigam.com/posts/adk-skill-design-patterns/)  
**示例代码**：[adk-skill-design-patterns（GitHub）](https://github.com/lavinigam-gcp/build-with-adk/tree/main/adk-skill-design-patterns)

---

本文是上述英文博文的**全文逐句汉译**，结构与标题层级与原文一致；SKILL 内嵌的**指令与代码**保持英文原文，便于与仓库对照。

---

## 系列与参考

本文是 ADK Skills **三部曲**的延伸，参考资料如下：

- [第一部分：SkillToolset 与渐进披露](https://lavinigam.com/posts/adk-agent-skills-part1/)
- [第二部分：基于文件的外部技能与 SkillToolset 内部机制](https://lavinigam.com/posts/adk-agent-skills-part2/)
- [第三部分：能写技能的技能——自扩展 ADK Agent](https://lavinigam.com/posts/adk-agent-skills-part3/)
- [ADK Core Skills](https://google.github.io/adk-docs/tutorials/coding-with-ai/)——构建 ADK agent 的官方技能

---

ADK 技能设计模式是用于组织 SKILL.md 文件的**可复用结构模板**；而 SKILL.md 是一种基于 Markdown 的指令格式，用来告诉 Google ADK 代理如何使用工具、生成内容或编排多步工作流。在本系列的[第 1–3 部分](https://lavinigam.com/posts/adk-agent-skills-part1/)中，我讲了基础——什么是 agent 技能、Google ADK 的 [SkillToolset](https://google.github.io/adk-docs/skills/) 如何实现渐进披露，以及如何用元技能构建自扩展代理。但在我自己的项目里，有一个问题反复出现：我知道怎么**创建**一个技能，但应该怎么**组织**它里面的内容？

一个封装 FastAPI 约定的技能，看起来和一个跑四步文档流水线的技能完全不同，但两者用的是同一种 SKILL。[Agent Skills 规范](https://agentskills.io/specification)定义了**容器**——SKILL.md 的 frontmatter、`references/`、`assets/`、`scripts/` 目录——却**没有**说明里面该写什么。那是**内容设计**问题，而不是格式问题。

有五种模式不断浮现。我在 Claude Code 的[捆绑技能](https://github.com/anthropics/skills)、[skills.sh](https://skills.sh/) 上的社区仓库、真实项目里，甚至在一篇[近期的 arXiv 论文](https://arxiv.org/html/2602.20867v1)里都见过——那篇论文正式归纳了七种系统级技能设计模式。本文命名其中**最实用的五种**，在 ADK 里用**可运行代码**分别展示，并帮你为具体用例选对模式。

读完本文，你将学会：

- 使用 **Tool Wrapper（工具封装）**，让代理对任意库或框架**立刻**像专家一样行事  
- 使用 **Generator（生成器）**，用可复用模板**稳定地产出**结构一致的文档  
- 使用 **Reviewer（评审者）**，让代理按清单给代码打分，并按**严重度**分组呈现问题  
- 使用 **Inversion（反转）**，把对话反过来——代理在行动之前**先向你提问**  
- 使用 **Pipeline（流水线）**，强制执行严格的**分步**工作流，并在阶段之间设置**检查点**

[克隆示例仓库 ↗](https://github.com/lavinigam-gcp/build-with-adk/tree/main/adk-skill-design-patterns)

**提要**

- **Tool Wrapper**——像库的速查表；只在相关时令代理应用其约定  
- **Generator**——像代理要填的表单；每次产出结构一致的文档  
- **Reviewer**——像评分量表；按清单给提交的代码打分，发现项按严重度分组  
- **Inversion**——代理先访谈你；在产出任何内容之前先问结构化问题  
- **Pipeline**——像带签字的菜谱；强制执行分步流程，避免跳步  
- 五种模式**可以组合**——Pipeline 里可以包含 Reviewer 步骤；Generator 可以在收集输入时使用 Inversion  

---

## 一种 SKILL.md 格式，多种用途

[Agent Skills 标准](https://agentskills.io/specification)已被超过 [30 种 agent 工具](https://agentskills.io/home)采用——Claude Code、Gemini CLI、GitHub Copilot、Cursor、JetBrains Junie 等。每个技能都遵循相同的目录布局：

```
skill-name/
├── SKILL.md          ← YAML frontmatter + markdown instructions (required)
├── references/       ← style guides, checklists, conventions (optional)
├── assets/           ← templates and output formats (optional)
└── scripts/          ← executable scripts (optional)
```

格式细节我在[第二部分](https://lavinigam.com/posts/adk-agent-skills-part2/)里写过，此处不重复。

**格式**告诉你如何**打包**一个技能，却不告诉你如何**设计**内容。指令应该是清单？工作流？一连串问题？`references/` 里该放风格指南、模板，还是查找表？答案取决于你的技能要做什么——**这就是模式登场的地方**。

本文中的五种模式都使用**同一种** SKILL.md 格式，但**组织内容的方式不同**——不同的指令风格、不同的资源类型、L2（指令）与 L3（references/assets）之间不同的关系。若需复习三层渐进披露，请参阅[第一部分的说明](https://lavinigam.com/posts/adk-agent-skills-part1/#what-are-skills-and-why-they-matter)。

---

## 快速回顾：SkillToolset 与三个层级

ADK 的 [SkillToolset](https://google.github.io/adk-docs/skills/) 通过三个**自动生成**的工具实现渐进披露。内部细节见[第二部分](https://lavinigam.com/posts/adk-agent-skills-part2/#wiring-adk-skills-with-skilltoolset)，这里只给**速览**：`list_skills` 列出技能名称与描述（L1）；`load_skill` 拉取完整指令（L2）；[load_skill_resource](https://google.github.io/adk-docs/skills/#define-skills-with-files) 按需加载参考文件与模板（L3）。代理在启动时每个技能大约只付出约 **100 token**，其余内容仅在需要时加载。

本文的模式示例中，五个技能都装入**同一个** `SkillToolset`。代理根据用户请求决定激活哪一个。

```python
# agent.py
import pathlib

from google.adk import Agent
from google.adk.skills import load_skill_from_dir
from google.adk.tools.skill_toolset import SkillToolset

SKILLS_DIR = pathlib.Path(__file__).parent / "skills"

skill_toolset = SkillToolset(
    skills=[
        load_skill_from_dir(SKILLS_DIR / "api-expert"),       # Pattern 1: Tool Wrapper
        load_skill_from_dir(SKILLS_DIR / "report-generator"), # Pattern 2: Generator
        load_skill_from_dir(SKILLS_DIR / "code-reviewer"),    # Pattern 3: Reviewer
        load_skill_from_dir(SKILLS_DIR / "project-planner"),  # Pattern 4: Inversion
        load_skill_from_dir(SKILLS_DIR / "doc-pipeline"),     # Pattern 5: Pipeline
    ],
)

root_agent = Agent(
    model="gemini-2.5-flash",
    name="pattern_demo_agent",
    instruction="Load relevant skills before acting on any user request.",
    tools=[skill_toolset],
)
```

每个技能 frontmatter 里的 **`description` 字段是最重要的一行**。它是代理的**搜索索引**——如果描述含糊，代理在**应该**激活技能时却**不会**激活。下面每种模式都会说明如何写**能稳定触发**的描述。

---

## 模式 1：Tool Wrapper——教代理掌握一个库

**Tool Wrapper** 是一种 agent 技能，它把某个库或工具的**约定、最佳实践与编码标准**打包成按需加载的知识，代理在处理该技术时才会加载。这是最简单的 SKILL.md 模式——**指令加参考文件**，没有模板和脚本。

Tool Wrapper 技能把库或工具的约定打包成按需知识；技能加载后，代理就像**领域专家**。可以联想：FastAPI 约定、Terraform 模式、安全策略，或数据库查询最佳实践。

这是最简单的模式。没有模板、没有脚本——只有告诉代理**遵循哪些规则**的指令，加上 `references/` 里存放的详细约定文档。

**Tool Wrapper 模式**：SKILL.md 由库相关关键词触发，从 `references/` 加载约定，代理将其作为**领域专长**应用。

```markdown
# skills/api-expert/SKILL.md
---
name: api-expert
description: FastAPI development best practices and conventions. Use when building, reviewing, or debugging FastAPI applications, REST APIs, or Pydantic models.
metadata:
  pattern: tool-wrapper
  domain: fastapi
---

You are an expert in FastAPI development. Apply these conventions to the user's code or question.

## Core Conventions

Load 'references/conventions.md' for the complete list of FastAPI best practices.

## When Reviewing Code
1. Load the conventions reference
2. Check the user's code against each convention
3. For each violation, cite the specific rule and suggest the fix

## When Writing Code
1. Load the conventions reference
2. Follow every convention exactly
3. Add type annotations to all function signatures
4. Use Annotated style for dependency injection
```

`references/conventions.md` 文件承载**真正的规则**——命名约定、路由定义、错误处理模式、异步与同步指引等。代理**仅在**激活该技能时加载此文件，从而保持基线上下文较小。

此处的 **`description` 至关重要**。它包含具体关键词——「FastAPI」「REST APIs」「Pydantic models」——与开发者**实际会输入**的内容相匹配。像「帮助处理 API」这类描述因为太泛而**很少**能触发。

### 何时使用 Tool Wrapper

当你希望代理对某个特定库、SDK 或内部系统应用**一致、专家级**的约定时。这是**采用最广**的模式——多个工程团队已将其开源供参考：

- Vercel [react-best-practices](https://github.com/vercel-labs/agent-skills)——来自 Vercel Engineering 的 40+ 条 React 与 Next.js 性能规则，按影响程度（CRITICAL → LOW）组织，在代理处理 React 或 Next.js 代码时按需加载  
- Supabase [supabase-postgres-best-practices](https://github.com/supabase/agent-skills)——涵盖 8 个类别的 Postgres 优化指南（查询性能、连接管理、RLS、安全等），结构化为按需参考  
- Google [gemini-api-dev](https://github.com/google-gemini/gemini-skills)——Google 官方的 Gemini API Tool Wrapper，编码构建 Gemini 应用的最佳实践，可直接安装到任何兼容 skills 的代理中  
- Google [adk-core-skills](https://github.com/google/adk-docs/tree/main/skills)——Google 官方 ADK 开发技能：6 个技能覆盖 ADK 开发者指南、速查表、评估、部署、可观测性与脚手架。可通过 `npx skills add google/adk-docs -y -g` 安装到任意编程类 agent（Gemini CLI、Claude Code、Cursor）。这些都是 Tool Wrapper，教编程代理**正确编写 ADK 代码**——ADK 团队在用与运行时 `SkillToolset` **同一套** SKILL.md 格式「吃自己的狗粮」。

该模式同样适用于**内部**工具：编写一个 `google-adk-conventions` 技能，编码你们团队的 ADK 习惯——默认用哪个模型、如何命名 agent、如何接线 toolsets、如何处理错误——你们团队构建的每个 ADK agent 都会**自动**遵循相同约定，而无需在每个系统提示里重复。

```markdown
# skills/google-adk-conventions/SKILL.md
---
name: google-adk-conventions
description: Google ADK coding conventions and best practices. Use when building,
  reviewing, or debugging any ADK agent, tool, or multi-agent system.
metadata:
  pattern: tool-wrapper
  domain: google-adk
---

You are an ADK expert. Apply these conventions when writing or reviewing ADK code.

## Agent Naming
- The `name` field must match the agent's directory name exactly (`search-agent/` → `name="search-agent"`)
- Use lowercase, hyphen-separated names: `search-agent`, not `SearchAgent`

## Model Selection
- Default to `gemini-2.5-flash` for most tasks (fast, cost-efficient)
- Use `gemini-2.5-pro` only for complex multi-step reasoning
- Define model as a constant, never hardcode inline: `MODEL = "gemini-2.5-flash"`

## Tool Definitions
Load `references/tool-conventions.md` for the complete rules. Key points:
- Names: verb-noun, snake_case — `get_weather`, `search_documents`, not `run` or `doStuff`
- Always add type hints: `city: str`, `user_id: int`
- No default parameter values — the LLM must derive or request all inputs
- Docstring is the LLM's primary manual — be precise, don't describe `ToolContext`

## Multi-Agent Systems
- The `description` field on sub-agents is your routing API — be specific, not generic
- Only one built-in tool (Google Search, Code Exec) per root agent
- Group related tools into a `BaseToolset` subclass when an agent has 5+ tools
```

**说明**：frontmatter 中的 `metadata` 字段类型为 `dict[str, str]`——ADK 会存储它，但**不**强制任何 schema。我用它为技能打上模式与领域标签，这在有 **20+** 个技能需要审计时很有帮助。

---

## 模式 2：Generator——产出结构化输出

**Generator** 技能通过填写**可复用模板**来生成文档、报告或配置。与 Tool Wrapper 不同，它同时使用两个可选目录：`assets/` 存放**输出模板**（要填入的结构），`references/` 存放**风格指南**（要遵循的质量规则）。指令负责编排——加载风格指南、加载模板、收集输入、填入内容。

**Generator 模式**：指令编排流程；`references/` 定义质量规则；`assets/` 提供输出模板。

```markdown
# skills/report-generator/SKILL.md
---
name: report-generator
description: Generates structured technical reports in Markdown. Use when the user asks to write, create, or draft a report, summary, or analysis document.
metadata:
  pattern: generator
  output-format: markdown
---

You are a technical report generator. Follow these steps exactly:

Step 1: Load 'references/style-guide.md' for tone and formatting rules.

Step 2: Load 'assets/report-template.md' for the required output structure.

Step 3: Ask the user for any missing information needed to fill the template:
- Topic or subject
- Key findings or data points
- Target audience (technical, executive, general)

Step 4: Fill the template following the style guide rules. Every section in the template must be present in the output.

Step 5: Return the completed report as a single Markdown document.
```

`assets/report-template.md` 中的模板规定每份报告**必须包含**的章节——执行摘要、背景、方法、发现、汇总表、建议、后续步骤等。`references/style-guide.md` 中的风格指南控制语气（如「第三人称、主动语态」）、版式（如「章节用 H2、小节用 H3」）与质量要求（如「执行摘要 150 词以内、后续步骤不得空洞」）。

代理在激活技能时通过 `load_skill_resource` 加载这两个文件。**模板**约束结构，**风格指南**约束质量。更换任一文件即可改变产出，**无需**修改指令。

### 何时使用 Generator

当输出**每次**都需要遵循**固定结构**——**一致性**比**创造性**更重要时。常见用途包括：

- **技术报告**——执行摘要、方法、发现、建议等，无论主题如何，顺序始终一致  
- **API 文档**——每个端点都用相同小节：说明、参数、请求/响应示例、错误码  
- **提交信息**——用模板强制执行 Conventional Commits（`feat:`、`fix:`、`docs:`），使仓库中每条提交读起来风格统一  
- **ADK agent 脚手架**——从模板生成新 ADK 项目的标准 `agent.py` + `__init__.py` + `.env` 结构，并预置你们团队的模型常量与指令风格  

---

## 模式 3：Reviewer——对照标准评估

**Reviewer** 技能根据存放在 `references/` 中的**清单**评估代码、内容或制品，生成**带分数**的发现报告，并按**严重度**分组。关键设计洞见：把**查什么**（清单文件）与**怎么查**（指令中的评审协议）**分开**。把 `references/review-checklist.md` 换成 `references/security-checklist.md`，在**同一技能结构**下就能得到完全不同的评审。

**Reviewer 模式**：用户提交代码，技能从 `references/` 加载清单，执行评审协议，生成按严重度分组的发现报告。

```markdown
# skills/code-reviewer/SKILL.md
---
name: code-reviewer
description: Reviews Python code for quality, style, and common bugs. Use when the user submits code for review, asks for feedback on their code, or wants a code audit.
metadata:
  pattern: reviewer
  severity-levels: error,warning,info
---

You are a Python code reviewer. Follow this review protocol exactly:

Step 1: Load 'references/review-checklist.md' for the complete review criteria.

Step 2: Read the user's code carefully. Understand its purpose before critiquing.

Step 3: Apply each rule from the checklist to the code. For every violation found:
- Note the line number (or approximate location)
- Classify severity: error (must fix), warning (should fix), info (consider)
- Explain WHY it's a problem, not just WHAT is wrong
- Suggest a specific fix with corrected code

Step 4: Produce a structured review with these sections:
- **Summary**: What the code does, overall quality assessment
- **Findings**: Grouped by severity (errors first, then warnings, then info)
- **Score**: Rate 1-10 with brief justification
- **Top 3 Recommendations**: The most impactful improvements
```

`references/review-checklist.md` 包含按类别组织的**实际规则**——正确性（严重度：error）、风格（warning）、文档（info）、安全（error）、性能（info）等。每个类别有具体、可检查项：例如「禁止可变默认参数」「函数不超过 30 行」「禁止通配符导入」。

我在一个**故意包含三处缺陷**的函数上做了测试——`PascalCase` 命名、可变默认参数、裸露的 `except:`——代理加载技能、取回清单后**三处都抓到了**。它将可变默认参数判为 **error**（正确——属于缺陷），将命名判为 **warning**（正确——属于风格），并生成了带评分的报告。驱动行为的是**清单**，而不是代理的预训练。

### 何时使用 Reviewer

凡是人类评审者会拿着**清单**工作的场景——Reviewer 技能都能将其编码并**一致**应用。常见用途：

- **代码评审**——按团队风格规则捕获可变默认值、缺失类型标注、裸露 `except:` 等；[Giorgio Crivellari](https://medium.com/google-cloud/i-built-an-agent-skill-for-googles-adk-here-s-why-your-coding-agent-needs-one-too-e5d3a56ef81b) 用 ADK 治理技能演示，代码质量分数从 **29% 提升到 99%**  
- **安全审计**——对提交代码运行 OWASP Top 10 类检查，在人工复审前按严重度分类  
- **编辑评审**——对照编辑部风格检查博客或文档（语气、标题结构、字数、禁用短语）  
- **ADK agent 评审**——对照你们团队的 `google-adk-conventions` 校验新 agent：命名、模型常量、工具 docstring、`description` 字段质量  

---

## 模式 4：Inversion——技能来「访谈」你

**Inversion** 翻转典型的代理交互：不是用户主导对话，而是技能指示代理在产出任何内容之前，通过**定义好的阶段**提出**结构化问题**。在收集到所需信息之前，代理**不会**行动。不需要特殊框架支持——Inversion **纯粹**是**指令编写**模式，依靠显式门禁（如「在完成所有阶段之前**不要**开始搭建」）把代理**拦住**。

**Inversion 模式**：技能通过分阶段提问驱动对话；**仅在**收齐答案后才合成输出。

```markdown
# skills/project-planner/SKILL.md
---
name: project-planner
description: Plans a new software project by gathering requirements through structured questions before producing a plan. Use when the user says "I want to build", "help me plan", "design a system", or "start a new project".
metadata:
  pattern: inversion
  interaction: multi-turn
---

You are conducting a structured requirements interview. DO NOT start building or designing until all phases are complete.

## Phase 1 — Problem Discovery (ask one question at a time, wait for each answer)

Ask these questions in order. Do not skip any.

- Q1: "What problem does this project solve for its users?"
- Q2: "Who are the primary users? What is their technical level?"
- Q3: "What is the expected scale? (users per day, data volume, request rate)"

## Phase 2 — Technical Constraints (only after Phase 1 is fully answered)

- Q4: "What deployment environment will you use?"
- Q5: "Do you have any technology stack requirements or preferences?"
- Q6: "What are the non-negotiable requirements? (latency, uptime, compliance, budget)"

## Phase 3 — Synthesis (only after all questions are answered)

1. Load 'assets/plan-template.md' for the output format
2. Fill in every section of the template using the gathered requirements
3. Present the completed plan to the user
4. Ask: "Does this plan accurately capture your requirements? What would you change?"
5. Iterate on feedback until the user confirms
```

**分阶段结构**是 Inversion 生效的原因。阶段 1 必须完成才能进入阶段 2。阶段 3 仅在**所有问题**回答之后触发。顶部的「在完成所有阶段之前**不要**开始搭建或设计」是**关键门禁**——没有它，代理往往在得到第一个回答后就**急于下结论**。

`assets/plan-template.md` 锚定合成步骤。它定义问题陈述、目标用户、规模需求、技术架构、不可妥协需求、建议里程碑、风险与缓解、决策日志等章节。代理用访谈答案填写该模板，无论对话如何展开，都能产出**一致**的输出。

### 何时使用 Inversion

凡是代理需要先向用户获取上下文才能有效工作的场景——它能避免最常见的失败模式：在**没有提问**的情况下，基于**假设**生成详细计划。常见用途：

- **需求收集**——在产出技术设计之前先访谈用户，确保计划反映**真实约束**而非猜测  
- **诊断式访谈**——在给出修复建议之前，按结构化清单排查（环境、版本、错误信息、复现步骤）  
- **配置向导**——在生成基础设施配置之前收集部署偏好（云厂商、区域、扩缩容需求）  
- **ADK agent 设计**——在脚手架新 ADK agent 之前访谈用户：需要哪些工具、哪个模型、是否多代理系统、路由约束是什么？  

---

## 模式 5：Pipeline——强制执行多步工作流

**Pipeline** 技能定义**顺序**工作流：每一步必须在下一步开始**之前**完成，并带有显式**门控条件**，防止代理跳过校验。这是**最复杂**的模式——不同于只加载参考资料的 Tool Wrapper，Pipeline 会使用全部三个可选目录（`references/`、`assets/`、`scripts/`），并在步骤之间加入**控制流**。**指令本身**就是工作流定义。

**Pipeline 模式**：步骤顺序执行，带菱形门控条件。「用户是否确认？」类门禁防止代理跳过校验。

```markdown
# skills/doc-pipeline/SKILL.md
---
name: doc-pipeline
description: Generates API documentation from Python source code through a multi-step pipeline. Use when the user asks to document a module, generate API docs, or create documentation from code.
metadata:
  pattern: pipeline
  steps: "4"
---

You are running a documentation generation pipeline. Execute each step in order. Do NOT skip steps or proceed if a step fails.

## Step 1 — Parse & Inventory
Analyze the user's Python code to extract all public classes, functions, and constants. Present the inventory as a checklist. Ask: "Is this the complete public API you want documented?"

## Step 2 — Generate Docstrings
For each function lacking a docstring:
- Load 'references/docstring-style.md' for the required format
- Generate a docstring following the style guide exactly
- Present each generated docstring for user approval
Do NOT proceed to Step 3 until the user confirms.

## Step 3 — Assemble Documentation
Load 'assets/api-doc-template.md' for the output structure. Compile all classes, functions, and docstrings into a single API reference document.

## Step 4 — Quality Check
Review against 'references/quality-checklist.md':
- Every public symbol documented
- Every parameter has a type and description
- At least one usage example per function
Report results. Fix issues before presenting the final document.
```

**门控条件**是定义性特征。「**未经用户确认不得进入第 3 步**」防止代理用**未评审**的 docstring 就汇编文档。顶部的「**不要**跳步；若某步失败则**不要**继续」强制执行顺序约束。没有这些门禁，代理往往会**一口气冲完**所有步骤，交出**跳过校验**的最终结果。

每一步加载不同资源。第 2 步加载 `references/docstring-style.md`（Google 风格 docstring 格式）。第 3 步加载 `assets/api-doc-template.md`（含目录、类、函数、常量等结构的输出形态）。第 4 步加载 `references/quality-checklist.md`（完整性与质量规则）。代理**仅为当前步骤**需要的资源支付上下文 token。

### 何时使用 Pipeline

任何**多步**且步骤之间有**依赖**、**顺序**重要的流程——若跳过某步会产生**错误**或**未经验证**的输出，应使用 Pipeline。常见用途：

- **文档生成**——解析代码 → 生成 docstring（经用户批准）→ 汇编文档 → 质量检查，阶段之间设门  
- **数据处理**——校验输入 → 转换 → 丰富 → 写出，每步成功后才运行下一步  
- **部署流程**——跑测试 → 构建制品 → 部署到预发 → 冒烟测试 → 晋升生产，带人工确认门  
- **ADK agent 上手**——访谈用户（Inversion）→ 脚手架文件（Generator）→ 按约定校验（Reviewer），将三种模式组合进一条 Pipeline  

---

## 如何选择合适的 ADK 技能模式

每种模式回答**不同**的问题。用下表找到合适起点；若仍不确定，再跟随原文中的**决策树**（yes/no 分支；**图示见英文原帖**）。

| Pattern | Use when… | Directories used | Complexity |
| --- | --- | --- | --- |
| Tool Wrapper | Agent needs expert knowledge about a specific library or tool | `references/` | Low |
| Generator | Output must follow a fixed template every time | `assets/`+`references/` | Medium |
| Reviewer | Code or content needs evaluation against a checklist | `references/` | Medium |
| Inversion | Agent must gather context from the user before acting | `assets/` | Medium — multi-turn |
| Pipeline | Workflow has ordered steps with validation gates between them | `references/`+`assets/`+`scripts/` | High |

**译表**：

| 模式 | 适用情形 | 使用的目录 | 复杂度 |
| --- | --- | --- | --- |
| Tool Wrapper | 代理需要关于某库或工具的专家级知识 | `references/` | 低 |
| Generator | 输出每次都必须遵循固定模板 | `assets/` + `references/` | 中 |
| Reviewer | 代码或内容需要按清单评估 | `references/` | 中 |
| Inversion | 代理必须先向用户收集上下文再行动 | `assets/` | 中（多轮） |
| Pipeline | 工作流有有序步骤且步骤间需校验门禁 | `references/` + `assets/` + `scripts/` | 高 |

模式可以**组合**。Pipeline 可以包含 Reviewer 步骤——例如 doc-pipeline 的第 4 步加载 `quality-checklist.md` 并对汇编文档做评估，即 Pipeline **内嵌** Reviewer。Generator 可以在产出前用 Inversion 收集输入。Tool Wrapper 可以作为参考文件**嵌**在 Pipeline 技能里。[arXiv 论文「SoK: Agentic Skills」](https://arxiv.org/html/2602.20867v1)（2026 年 2 月）发现，生产系统通常组合 **2–3** 种模式，最常见组合之一是**元数据驱动的披露**（即本文的 Tool Wrapper）加**市场/分发**机制。

若仍不确定哪种模式合适，请从原文的决策树开始：跟随 yes/no 分支找到适合用例的模式。大多数技能可以**清晰**映射到某一种模式。

---

## ADK 技能生态

你**不必**每个技能都从零编写。[Agent Skills 标准](https://agentskills.io/specification)意味着：为 Claude Code、Gemini CLI、Cursor 或 [30+ 兼容代理](https://agentskills.io/home)编写的任意技能，都可通过 `load_skill_from_dir()` 在 ADK 中加载。获取途径包括：

- **[skills.sh](https://skills.sh/)**——最大的社区市场（**86,000+** 次安装）；可用 `npx skills add …` 浏览并安装技能。  
- 从任意兼容 skills 的来源加载社区技能时，可将技能目录传给 `load_skill_from_dir()`，例如：

```python
# Loading a community skill from any skills-compatible source
community_skill = load_skill_from_dir(
    pathlib.Path(__file__).parent / "skills" / "community-skill-name"
)
```

- 安装 Google ADK 文档技能示例：`npx skills add google/adk-docs -y -g`

---

*翻译说明：技术术语（SkillToolset、Tool Wrapper、Generator、Reviewer、Inversion、Pipeline、frontmatter 等）在文中首次或关键处保留英文或中英并用，便于与 ADK / Agent Skills 文档对照。*
