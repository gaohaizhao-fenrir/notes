---
name: rswift-string-extends-import
description: Swift/SwiftUI 项目中用 R.swift 与项目根 `extends/string_extends.md`（YAML）驱动各语言 `Localizable.strings` 的导入与同步；业务代码通过 `R.string.localizable.<key>()` 引用文言。配置优先级、占位、磁盘与配置不一致时的处理等细则以正文为准。适用于导入本地化文言、批量写入 Localizable、按 string_extends 多语言约定操作、新建或维护 `string_extends.md`。
---

# R.swift + string_extends 文言导入

## 目的

在编码过程中，凡涉及**向工程导入本地化文言**或**一次性导入整项目/大批字符串**，统一走：

1. **R.swift**（SwiftPM）+ 各语言 **`*.lproj/Localizable.strings`**
2. 项目根目录 **`extends/string_extends.md`** 作为多语言与**键名风格**的**唯一权威配置**（优先级高于磁盘上的 `.strings`）
3. 代码侧只通过 **`R.string.localizable.<key>()`**（或项目中等价的 R 生成函数调用）使用文言，**不**在业务代码里写译文字面量，也**不**手写 `NSLocalizedString("raw_key", ...)` 形式的裸 key 字符串

### 配置与 `.strings` 的方向（必须遵守）

- **单向关系**：**先** `extends/string_extends.md`（YAML），**后** `.lproj` / `Localizable.strings`。用户在 `string_extends.md` 中增删语言、改键名风格 → 据此维护、生成或同步 `.strings`（及 Xcode 资源引用等工程步骤，按项目约定）。
- **禁止反向推断**：**不得**因为磁盘上已存在某个 `\<lang>.lproj` 或某份 `Localizable.strings`，就自动把该语言**追加**进 `target_language`，或为了「与磁盘对齐」而改写 `string_extends.md`。磁盘多出配置未声明的语言时，只能**列出差异并询问用户**（删除多余资源，或**由用户亲自编辑** `string_extends.md` 后再按新配置执行）。
- **新增语言的正途**：仅在用户**明确修改** `string_extends.md` 将某语言写入 `target_language` 之后，才为该语言创建/同步 `.strings`。

本 skill 仅做：**读取 `extends/string_extends.md` + 生成/导入键值 + 改写调用处**。
若项目还缺少 R.swift 的 SPM 接入、缺少 `R.generated.swift` 构建期生成等前置能力，本 skill 会**提醒开发者手动完成**，并在前置未就绪前暂停导入/改写。

## 前置检查（必须先做）

1. **R.swift（SPM）**  
   - 确认 target 已依赖 `RswiftLibrary`（或项目实际使用的 R.swift product 名）。  
   - **若未集成**：提醒开发者**手动在 Xcode 中添加 Swift Package**，或在其同意下由 Agent 改工程；未完成前不要假装已可用。

2. **`.strings` 与 `.lproj`**  
   - **以 `string_extends.md` 中的 `target_language` 为准**，检查是否已有对应 `\<lang>.lproj/Localizable.strings`。  
   - 缺失时按 `string_extends.md`（或下文默认）创建目录与文件；内容可为空或仅占位，但结构要齐。  
   - **同时**对照磁盘：若某 `\<lang>.lproj/Localizable.strings` **已存在**，但 **`<lang>` 不在**当前 `target_language` 中，按下文 **「本地存在但未在 `target_language` 声明的语言」** 处理（须先询问用户，**禁止擅自删除**，也**禁止**为「对齐磁盘」而改写 `string_extends.md`）。

3. **`extends/string_extends.md`（仅该文件）**  
   - 本 skill **只**读取该路径的 `string_extends.md`（不读取任何其他 EXTEND/i18n 配置文件）。  
   - 若不存在：在**项目根目录**创建 `extends/`，并新建 `string_extends.md`，内容使用文末**最小模板**（含 YAML + **固定工作流一行**，缺一不可）。
   - 若存在：读取并解析其中的 YAML，作为后续导入与键名规则的依据。
   - 必须在 `string_extends.md` 内声明：该文件**仅用于** `.strings` 多语言本地化配置（不用于翻译模式/词条工作流偏好）。
   - 建议在文件顶部写入注释（团队可按需翻译）：`This file is only for .strings multilingual resources.`（或中文等价表述）。
   - **固定工作流一行**：与最小模板末尾列表项逐字一致；生成或补全 `string_extends.md` 时**必须**包含（`rswift-string-extends-import` + 核对 `.strings`），勿省略。

## `string_extends.md` 格式（YAML）

- 使用 **YAML** 块（可整体放在一个 fenced code 块内，或纯 YAML 文件视团队约定而定；**以可读、可解析为准**）。
- **`target_language`**：`string` 或 `string[]`，默认维护的目标语言（BCP 47 或与工程 `.lproj` 名称一致，如 `ja`、`en`、`zh-Hans`）。
  - **未写时视为 `[ja, en]`**（与最小模板一致：日语优先、英语次之；若项目需要其他语言组合，在 `string_extends.md` 里显式写出）。
- **`default_mode`**：资源**键名**的命名风格（**不是**翻译 skill 里的 quick/normal/refined）。

### `default_mode` 可选值

| 值 | 含义 | 示例 |
|----|------|------|
| `camelCase` | 小驼峰 | `userName` |
| `PascalCase` | 大驼峰 | `UserName` |
| `snake_case` | 蛇形 | `user_name` |
| `SCREAMING_SNAKE_CASE` | 全大写下划线 | `USER_NAME` |
| `kebab-case` | 短横线 | `user-name` |

同一项目内应统一为一种；新 key 必须遵守该风格。

### 最小模板（新建文件时用）

新建 `extends/string_extends.md` 时应**至少包含**下面全文（**标题 + YAML 块 + 工作流一行**，缺一不可）。默认语言为 **日语 + 英语**；若工程主语言不是 `ja`/`en`，请按产品需求在 YAML 中**显式写出** `target_language`，**再**使 `.lproj` 与配置一致（**不要**根据现有磁盘语言反推 YAML）。

````markdown
# This file is only for .strings multilingual resources.（本文件仅用于 .strings 多语言本地化。）

```yaml
target_language: [ja, en]
default_mode: snake_case
```

- 修改本文件后执行任务：**`rswift-string-extends-import`** + 核对 `.strings`。
````

（上文为 `string_extends.md` 的完整最小结构；复制到项目时保留内层 \`\`\`yaml 围栏与末尾列表项。）

## 导入规则

### 禁止擅自修改既有文言

- 各语言 `Localizable.strings` 中**已经写入**的译文，若属于产品/文案已审定的固定表述，**在本次任务未明确要求修改时，一律保持原样**。
- **禁止**因「读起来更通顺」「更符合本地化习惯」等理由，私自改写**非本次导入范围**的 key 或**其他语言**文件中的 value。
- 仅当用户**显式**要求修改某条或某语言的文言时，才在对应文件中更新该内容。

### 新增 `target_language` 中的语言但未提供译文

- 当 `string_extends.md` 的 `target_language` **新增**某一种语言（例如追加 `es`），而用户**尚未提供**该语言的任何译文时：应新建或更新 `\<lang>.lproj/Localizable.strings`，使 **key 集合与其他语言完全一致**，**每个 key 的 value 均为空字符串 `""`**。
- **禁止**用机器翻译或主观臆测为该语言填写 value；占位文件仅用于结构对齐与后续补译。

### 多语言 `target_language` + 仅一种语言的译文

- 将**有译文**的内容写入 **`target_language` 数组第一个**语言对应的 `Localizable.strings`。  
- 对其余 `target_language` 中的语言：为**相同 key** 各写一行，`value` 为**空字符串** `""`（占位，便于后续翻译或 CI 检查）。

### 多语言 `target_language` + 同时提供多语言译文

- 当用户输入/表格数据中**同时给出了**多个 `target_language` 语言的译文（例如 `zh` + `en` 都有值），则对每个 key 分别写入到其对应语言的 `\\<lang>.lproj/Localizable.strings`。
- 若某个 `target_language` 语言在输入中缺失：仍要为**相同 key** 写入空字符串 `""`（占位，保持多语言 key 集一致）。

### 导入语言不在 `target_language` 中

典型例子：配置为 `target_language: [ja, en]`，但本次导入的是**中文**或**仅英文**等，且工程里**没有**对应语言的 `.lproj`（如无 `zh-Hans`）。

**必须先停步询问用户**，明确选一（或用户给出等价决策）：

- 是否**新建**该语言对应的 `\<lang>.lproj/Localizable.strings`，并（可选）是否把该语言**追加**进 `string_extends.md` 的 `target_language`；或  
- 是否**临时**把该批文言写入**现有**某一语言文件（例如写入 `ja`），并说明后续需要翻译或调整。

**禁止**在未获用户确认前，擅自把中文塞进 `ja` 或删除用户预期语言。

### 本地存在但未在 `target_language` 声明的语言

与上一节相反：不是「要导入的语言不在列表里」，而是 **工程里已经有** `\<lang>.lproj/Localizable.strings`（或项目约定的 `.strings` 路径），但 **`extends/string_extends.md` 里解析出的 `target_language` 不包含该 `<lang>`**（下称「多余语言」）。

- **权威在配置**：此处以 **`string_extends.md` 为对**，磁盘多出来的语言**不代表**应自动把 YAML 改成包含该语言。
- **必须先做对照**：列出工程内实际存在的语言目录/文件（语言码与路径），与 YAML 中的 `target_language` 逐项比对，找出**仅在磁盘存在、未在配置声明**的 `<lang>`。
- **禁止**在未获用户**明确同意**前，擅自删除任何多余的 `Localizable.strings`、整个 `\<lang>.lproj` 或其它本地化资源（避免误删尚未迁移的译文或团队仍在用的 bundle 语言）。
- **禁止**Agent **自动**编辑 `string_extends.md` 以「接纳」多余语言；**仅当用户本人**在 `string_extends.md` 中把该 `<lang>` 加入 `target_language` 后，才将「多余语言」视为正式维护语言并同步 `.strings`。
- **必须询问用户**，并给出清晰选项，例如：
  - **删除**：移除对应 `\<lang>.lproj`（或项目中等价的语言资源目录），使磁盘与当前 `string_extends.md` **一致**；删除后按项目流程**重新运行** R.swift 生成（如 `rswift.sh`），更新 `R.generated.swift` 等；或  
  - **保留并改配置**：用户**亲自**在 `extends/string_extends.md` 的 `target_language` 中加入 `<lang>`，**之后**再按新配置维护 `.strings`（Agent 不在未获用户编辑的前提下代写 YAML）。
- 语言码与目录名应对齐工程约定（如 `zh` 与 `zh-Hans`）：对照时说明实际文件夹名，避免误判。

### 键名生成

- 新 key 必须符合 `default_mode`。  
- 若用户提供了 key 列表：规范化到 `default_mode`（必要时重命名并同步所有语言文件 + 代码引用）。  
- 若只有中文/英文等自然语言文案：生成**语义化**英文片段再按 `default_mode` 变换（避免用整句原文作 key）；与用户已有命名前缀/模块前缀冲突时优先跟随项目既有 `.strings` 前缀约定。

## 代码侧要求

- 替换 `Text("...")`、`NSLocalizedString(...)`、字符串插值里的硬编码用户可见文案为 **`R.string.localizable.<key>()`**（或当前 R 生成 API 中与 `func ...() -> String` 一致的调用）。  
- 若生成的资源访问器为 `var` 形式，应提醒开发者在项目侧调整为函数形式（构建期生成脚本/后处理由开发者或其现有脚本负责）；本 skill 只负责把调用改成统一的 `R.string.localizable.<key>()` 形式。

## 输出格式（回复用户时用）

```markdown
# 文言导入 / string_extends 更新

## 配置
- `extends/string_extends.md`：…（路径、target_language、default_mode）

## 文件变更
- 新增或更新的 `.lproj` / `Localizable.strings`：…

## 代码
- 已改为 `R.string.localizable.*()` 的位置：…

## 待你确认（若有）
- …
- 磁盘上存在但 `target_language` 未声明的语言：是否删除对应 `Localizable.strings` / `\<lang>.lproj`（已询问 / 用户已选择保留或删除）
```

## 质量检查清单

- [ ] SPM 中 R.swift 已就绪，或已明确提醒手动导入并暂停自动化步骤  
- [ ] `extends/string_extends.md` 存在且 YAML 可读，且含最小模板中的**工作流一行**（`rswift-string-extends-import` + 核对 `.strings`）  
- [ ] 各 `target_language` 均有对应 `.strings`（或已按用户选择新建）  
- [ ] 已核对磁盘上的 `*.lproj/Localizable.strings`（或项目约定路径）与 `target_language`：**若存在「多余语言」**，已向用户说明并列出差集，**已询问是否删除或请用户自行改 YAML**；**未**为对齐磁盘而擅自改写 `string_extends.md`；未获同意前**未擅自删除**  
- [ ] **未擅自修改**任何既有 `.strings` 中**已规定/已审定**的文言（本次任务未明确要求修改的 key 与其他语言文件均保持原样）  
- [ ] **新增语言但未提供译文**时：该语言文件为**全 key + value 均为 `""`**，**未编造**任何译文  
- [ ] 「仅一种语言有译文」时，首语言有值、其余语言同 key 空串  
- [ ] 导入语言不在列表内时，已取得用户明确选择  
- [ ] 调用处无裸译文字面量（除 debug 等例外）、无裸 key 字符串路径
