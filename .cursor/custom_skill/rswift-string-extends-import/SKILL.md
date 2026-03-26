---
name: rswift-string-extends-import
description: 在 Swift/SwiftUI 项目中用 R.swift + `.strings` 管理本地化：只读取项目根下 `extends/string_extends.md` 的 YAML（`target_language`、`default_mode` 键名风格）。批量导入本地化文言时：如果输入只提供了某一种目标语言的译文，则按 `target_language` 第一个语言写入，其余目标语言用空字符串占位；如果输入同时提供了多个目标语言的译文，则分别写入对应语言的 `.lproj/Localizable.strings`，缺失的目标语言仍用空字符串占位。当导入语言不在 `target_language` 时先询问用户如何处理（新建该语言 .lproj/或映射到现有语言）。调用处一律改为 `R.string.localizable.<key>()` 等函数形式，禁止散落原始文言或裸 key 字符串。用于“导入本地文言 / 批量写入 Localizable.strings / 按 string_extends 多语言约定导入 / 新建 string_extends.md”。
---

# R.swift + string_extends 文言导入

## 目的

在编码过程中，凡涉及**向工程导入本地化文言**或**一次性导入整项目/大批字符串**，统一走：

1. **R.swift**（SwiftPM）+ 各语言 **`*.lproj/Localizable.strings`**
2. 项目根目录 **`extends/string_extends.md`** 作为多语言与**键名风格**的单一事实来源
3. 代码侧只通过 **`R.string.localizable.<key>()`**（或项目中等价的 R 生成函数调用）使用文言，**不**在业务代码里写译文字面量，也**不**手写 `NSLocalizedString("raw_key", ...)` 形式的裸 key 字符串

本 skill 仅做：**读取 `extends/string_extends.md` + 生成/导入键值 + 改写调用处**。
若项目还缺少 R.swift 的 SPM 接入、缺少 `R.generated.swift` 构建期生成等前置能力，本 skill 会**提醒开发者手动完成**，并在前置未就绪前暂停导入/改写。

## 前置检查（必须先做）

1. **R.swift（SPM）**  
   - 确认 target 已依赖 `RswiftLibrary`（或项目实际使用的 R.swift product 名）。  
   - **若未集成**：提醒开发者**手动在 Xcode 中添加 Swift Package**，或在其同意下由 Agent 改工程；未完成前不要假装已可用。

2. **`.strings` 与 `.lproj`**  
   - 根据下节 `target_language` 检查是否已有对应 `\<lang>.lproj/Localizable.strings`。  
   - 缺失时按 `string_extends.md`（或下文默认）创建目录与文件；内容可为空或仅占位，但结构要齐。

3. **`extends/string_extends.md`（仅该文件）**  
   - 本 skill **只**读取该路径的 `string_extends.md`（不读取任何其他 EXTEND/i18n 配置文件）。  
   - 若不存在：在**项目根目录**创建 `extends/`，并新建 `string_extends.md`，内容使用文末**最小模板**。
   - 若存在：读取并解析其中的 YAML，作为后续导入与键名规则的依据。
   - 必须在 `string_extends.md` 内声明：该文件**仅用于** `.strings` 多语言本地化配置（不用于翻译模式/词条工作流偏好）。
   - 建议在文件顶部写入注释（团队可按需翻译）：`This file is only for .strings multilingual resources.`（或中文等价表述）。

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

新建 `extends/string_extends.md` 时应**至少包含**下面 YAML。默认语言为 **日语 + 英语**；若工程主语言不是 `ja`/`en`，请把 `target_language` 改成与 `.lproj` 一致的语言码列表。

```yaml
# This file is only for .strings multilingual resources.（或中文：本文件仅用于 .strings 多语言本地化。）
target_language: [ja, en]
default_mode: snake_case
```

## 导入规则

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
```

## 质量检查清单

- [ ] SPM 中 R.swift 已就绪，或已明确提醒手动导入并暂停自动化步骤  
- [ ] `extends/string_extends.md` 存在且 YAML 可读  
- [ ] 各 `target_language` 均有对应 `.strings`（或已按用户选择新建）  
- [ ] 「仅一种语言有译文」时，首语言有值、其余语言同 key 空串  
- [ ] 导入语言不在列表内时，已取得用户明确选择  
- [ ] 调用处无裸译文字面量（除 debug 等例外）、无裸 key 字符串路径
