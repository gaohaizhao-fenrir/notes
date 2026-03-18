<!--
Sync Impact Report
- Version change: N/A → 1.0.0
- Modified principles:
  - PRINCIPLE_1: 文档与规范语言 → 中文优先
  - PRINCIPLE_2: 技术栈 → SwiftUI + Apple 规范
  - PRINCIPLE_3: 目录与可见性约束
  - PRINCIPLE_4: 本地资源统一由 R.swift 管理
  - PRINCIPLE_5: 平台支持策略（iOS 17+）
- Added sections:
  - Section 2: 实施与技术约束
  - Section 3: 开发流程与审查
- Removed sections:
  - 模板中的示例说明与占位符
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ updated
  - .specify/templates/spec-template.md ✅ updated
  - .specify/templates/tasks-template.md ✅ updated
  - .specify/templates/commands/*.md ⚠ pending（当前目录下无命令模板文件）
- Runtime docs:
  - README.md ⚠ pending（文件不存在或尚未定义与宪章的对应说明）
- Deferred TODOs:
  - 无（所有占位符已具体化）
-->

# Notes iOS App Constitution

## Core Principles

### 原则一：中文优先的文档与规范

- 所有由 `/speckit.spec`, `/speckit.plan`, `/speckit.tasks` 等命令生成的 `spec.md`、`plan.md`、
  `tasks.md` 等文档，**默认必须使用中文撰写**，包括标题、说明、用户故事、任务描述等。
- 如确有必须使用英文的内容（例如 Apple / iOS / Xcode / Swift / 第三方库要求的英文 API 名称、
  标识符、配置 key、系统术语），**保留英文原文**，并在必要时追加简短中文解释。
- 对外暴露的接口、配置字段如需严格对齐平台或框架文档，**优先保持与官方英文文档一致**，
  避免引入歧义翻译。
- 评审规范：如果文档中存在可以使用中文却仅给出英文抽象描述的部分，评审时应要求补充中文说明。

**Rationale**：项目团队主要使用中文沟通，通过统一的中文文档可以降低理解成本，但同时必须尊重
官方英文 API 与术语，避免在关键技术细节上产生翻译歧义。

### 原则二：SwiftUI 开发与 Apple 官方规范

- 本项目的 UI 层 **统一采用 SwiftUI 实现**，不再引入新的 UIKit 视图层实现，除非存在 SwiftUI
  无法满足且经过审慎评估的场景。
- 代码风格与架构设计应尽量遵循 Apple 官方最佳实践，包括但不限于：
  - 遵循 Swift API Design Guidelines；
  - 遵循最新的 Human Interface Guidelines（HIG）；
  - 在合适场景下优先使用 `async/await` 与结构化并发；
  - 使用 `ObservableObject` / `State` / `StateObject` / `EnvironmentObject` 等
    SwiftUI 官方推荐的状态管理方式。
- 引入第三方框架或工具时，必须保证与 SwiftUI 及 iOS 17+ 平台良好兼容，且不会破坏
  Apple 的审核要求与隐私合规要求。

**Rationale**：通过统一使用 SwiftUI 与官方规范，可以在 iOS 17+ 平台上获得更好的系统整合体验、
更少的历史包袱、更高的可维护性和更顺滑的升级路径。

### 原则三：目录结构与隐藏文件约束

- 工程目录与子目录设计必须**直观、可读、无多余隐藏目录**，任何以 `.` 开头的隐藏目录或文件
  （例如 `.cache`、`.tmp`、自定义隐藏配置目录等），**不得由工具或脚本私自创建**。
- 如确因工具或工作流需要创建隐藏目录（例如某些构建工具的缓存），必须：
  - 事先在规范或 README 中说明用途与影响；
  - 主动征求开发者同意后再引入；
  - 尽可能将其排除在源码管理（git）之外，或清晰标注。
- speckit 相关命令及自动化脚本在生成文件或目录前，**不得增加新的隐藏目录**，如确有必要，
  必须在 PR 或说明文档中明确提出并获开发者确认。

**Rationale**：过多的隐藏目录会降低工程可读性，也容易引入意料之外的状态与冲突。通过严格约束，
确保工程结构简洁透明，降低维护成本。

### 原则四：本地资源统一由 R.swift 管理

- 所有本地资源文件（包括但不限于：文案字符串、图片、颜色、字体、JSON 配置等），
  **必须通过 R.swift 统一管理和访问**，禁止在生产代码中直接使用硬编码字符串访问 Bundle 资源。
- 新增资源时，必须：
  - 按约定的目录结构与命名规范添加到工程中；
  - 确保 R.swift 能正确扫描到资源；
  - 在代码中仅通过 `R.` 命名空间访问对应资源。
- 若某类资源暂不适合由 R.swift 管理（例如运行时下载的远程资源），应在设计文档中说明原因，
  并尽量保持访问方式的一致性与可测试性。

**Rationale**：通过 R.swift 统一管理本地资源，可以避免硬编码路径与拼写错误，提高类型安全性，
并在重构或资源重命名时大幅降低回归风险。

### 原则五：平台支持策略（iOS 17+）

- 本项目的 **最小支持系统版本为 iOS 17**，所有新功能、组件与依赖必须在 iOS 17 及以上环境下
  可用并通过测试。
- 如确需引入仅在更高系统版本（例如 iOS 18）可用的能力，应：
  - 在设计与实现中提供合理的降级策略或特性检测；
  - 在规范与用户文档中明确说明差异行为。
- 如未来要调整最小支持版本（例如提升到 iOS 18），属于**重大变更**，必须通过宪章修订流程，
  并在版本号上体现为 MAJOR 或 MINOR 级别变更（视是否引入不兼容行为而定）。

**Rationale**：统一的最低支持版本可以简化技术决策，充分利用新系统能力，减少兼容性分支，
同时在产品层面保持对用户的预期一致。

## 实施与技术约束

- **语言与框架**：
  - 主语言为 Swift；
  - UI 层统一使用 SwiftUI；
  - 严格遵守 Apple 开发规范及 Human Interface Guidelines。
- **资源管理**：
  - 所有本地资源文件通过 R.swift 统一管理和访问；
  - 禁止在生产代码中直接硬编码资源路径或名称。
- **目录与文件**：
  - 不得擅自创建新的隐藏目录（以 `.` 开头）；
  - 如需隐藏目录或特殊缓存机制，必须事先与开发者确认并在文档中说明。
- **文档语言**：
  - speckit 系列命令生成的规格文档与任务文档默认使用中文；
  - 必须使用英文的技术名词或 API 名称时，保持与官方文档一致。

## 开发流程与质量门禁

- **Constitution Check（宪章检查）**：
  - 在编写 `plan.md` 时，必须显式检查：
    - 是否明确声明使用 SwiftUI 与 iOS 17+ 目标平台；
    - 是否规划了 R.swift 资源管理方案；
    - 是否避免引入新的隐藏目录或隐式文件结构；
    - 是否约定后续 spec / tasks 使用中文描述。
  - 任何违反上述原则的设计，必须在 `plan.md` 中给出理由与替代方案评估。
- **规格与任务分解**：
  - `spec.md` 中的用户故事与验收标准使用中文描述；
  - `tasks.md` 中的任务描述同样使用中文，并在需要时引用英文 API 名或文件路径。
- **代码评审**：
  - 评审时需检查：
    - SwiftUI 使用是否符合 Apple 官方建议；
    - 是否通过 R.swift 访问本地资源；
    - 是否引入了新的隐藏目录或不透明的工程结构；
    - 是否存在可以中文化而未中文化的核心说明。

## Governance

- **宪章优先级**：
  - 本宪章对本仓库内使用 speckit 相关命令生成的规范文档与开发流程具有最高约束力；
  - 当其他文档（如 README、内部 wiki）与本宪章冲突时，以本宪章为准。
- **修订流程**：
  - 任何对核心原则或治理流程的修改，必须通过 Pull Request 完成；
  - PR 中需明确说明修改动机、影响范围及版本号变更类型（MAJOR / MINOR / PATCH）；
  - 至少一名对 iOS / SwiftUI / Apple 规范熟悉的开发者审阅通过后方可合并。
- **版本号策略（CONSTITUTION_VERSION）**：
  - **MAJOR**：移除或实质性重定义现有原则，或引入不兼容的治理变更；
  - **MINOR**：新增原则、增加新的强制性门禁或对现有原则进行显著扩展；
  - **PATCH**：措辞澄清、错别字修复或不改变含义的细节补充。
- **合规检查**：
  - speckit 相关命令在生成计划与任务前，应显式参考本宪章的相关部分；
  - 代码评审 Checklist 中应包含对 SwiftUI 规范、R.swift 使用、隐藏目录约束、
    文档语言规范的检查。

**Version**: 1.0.0 | **Ratified**: 2026-03-18 | **Last Amended**: 2026-03-18
