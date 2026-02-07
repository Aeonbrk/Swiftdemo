# Project Overview: Learning Plan to Cards & Todos

> 文档用途：将历史设计稿与 MVP 计划合并为一份“可执行、可维护、以代码为准”的项目说明。
>
> 最后核对日期：2026-02-07（已对照真实代码与构建结果）

## 1. 项目定位

这是一个原生 SwiftUI 应用：把用户输入的长学习计划文本，经过 OpenAI-compatible LLM 两步处理后，生成可编辑的学习产物。

核心目标：

- Step 1：生成结构化计划（`planJSON` + `planMarkdown`）与引用相关信息（`claims` + `citations`）。
- Step 2：基于结构化计划派生 `flashcards` 与 `todos`。
- 本地持久化：使用 SwiftData 保存原始输入与派生结果。
- 可导出：Flashcards 导出 TSV/CSV，Todos 导出 CSV。

## 2. 设计合并结论（来自两份原始文档）

两份文档的共同主线一致：

- 采用 `Core`（可复用能力）+ `demo`（SwiftUI UI）分层。
- 优先交付 macOS 体验，同时保留 iOS/visionOS 复用边界。
- API Key 仅存 Keychain，不落盘明文。
- 引用真实性自动验证不在 MVP，但数据层要预留字段。

本说明文档对以上设计进行了代码化校准，下面“当前实现状态”以代码为唯一事实来源。

## 3. 当前实现状态（以代码为准）

### 3.1 架构现状

- `Core` Swift Package：模型、LLM client、两步 pipeline、导出器、模型容器。
- `demo` App：文档列表 + 编辑与生成 UI + Provider 设置（macOS）+ Keychain 集成。

代码入口：

- App 入口：`demo/demoApp.swift`
- 主界面：`demo/ContentView.swift`
- 设置界面（macOS）：`demo/SettingsView.swift` + `demo/ProviderEditorView.swift`
- 生成辅助：`demo/PlanInputGenerationSupport.swift`
- 核心包：`Core/Package.swift`

### 3.2 能力完成度

| 能力 | 设计目标 | 当前状态 |
|---|---|---|
| 多文档管理 | 支持多份计划、原文保存 | 已实现（列表、新建、删除、持久化） |
| Step 1 生成 | 计划 + 引用结构化输出 | 已实现（Step1Pipeline + 解码 + 入库） |
| Step 2 生成 | 派生 Cards/Todos | 已实现（Step2Pipeline + 解码 + 入库） |
| Provider 配置 | 可配置 baseURL/model/headers | 已实现（含预设模板与激活逻辑） |
| API Key 安全存储 | Keychain 存储与读取 | 已实现 |
| 导出 | Cards TSV/CSV、Todos CSV | 已实现（macOS 通过 `NSSavePanel`） |
| 引用字段预留 | verification status 元数据 | 已实现（字段已落模型） |
| 自动真实性校验 | 自动抓取和验证引用 | 未实现（仅预留字段） |
| iOS 等平台完整设置体验 | Settings/Provider UI 跨平台可用 | 未完全实现（Settings 仅 macOS） |
| `.apkg` / AnkiConnect | 深度 Anki 集成 | 未实现 |

## 4. 目录与职责

- `Core/Sources/Core/Models/`：SwiftData 实体（`PlanDocument`、`PlanOutline`、`TodoItem`、`Flashcard`、`Claim`、`Citation`、`GenerationRecord`、`LLMProvider`）。
- `Core/Sources/Core/LLM/`：OpenAI-compatible 协议层与 Provider 预设。
- `Core/Sources/Core/Pipeline/`：Step1/Step2 生成与 JSON 解码容错。
- `Core/Sources/Core/Export/`：TSV/CSV 导出器。
- `Core/Sources/Core/Persistence/`：ModelContainer 构建。
- `Core/Tests/CoreTests/`：核心单元测试（模型、pipeline、导出、provider 预设）。
- `demo/`：SwiftUI 应用层与 Keychain 访问。

## 5. 数据模型摘要

关键实体关系：

- `PlanDocument` 为聚合根，关联 `outline`、`todos`、`flashcards`、`claims`、`citations`、`generations`。
- `Claim` 与 `Citation` 建立关联，用于“结论-引用”追溯。
- `Citation` 包含 `verificationStatusRaw` 与 `verificationMetadataJSON`，为后续校验扩展预留。
- `LLMProvider` 保存 Provider 元信息与 Keychain 账户引用，`isActive` 表示当前激活项。

## 6. 运行流程（当前实现）

1. 用户在 Input 页输入原文并点击 `Generate (Step 1)`。
2. 应用读取激活 Provider 与 Keychain API Key，调用 `Step1Pipeline`。
3. 结果写入 `PlanOutline`、`Claim`、`Citation`，并追加 `GenerationRecord`。
4. 用户点击 `Generate (Step 2)`，基于 `planJSON/planMarkdown` 调用 `Step2Pipeline`。
5. 结果覆盖更新 `Flashcard` 与 `TodoItem`，并记录历史。
6. 用户在 Cards/Todos 里编辑内容，或导出为 TSV/CSV。

## 7. 构建与测试（已验证）

在当前仓库可直接执行：

```bash
swift test --package-path Core
xcodebuild -project demo.xcodeproj -scheme demo -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project demo.xcodeproj -scheme demo -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

核对结果（2026-02-07）：

- `Core` 测试通过（14 tests）。
- macOS build 成功。
- iOS Simulator build 成功。

## 8. 当前已知边界

- Settings 场景与 Provider 编辑 UI 仅在 macOS 编译路径启用。
- 引用真实性仍为“可展示状态”，没有自动验证服务。
- Pipeline 目前依赖模型遵守 JSON 输出约定，虽有容错提取，但未引入更严格 schema 版本治理。
- UI 自动化测试尚未建立，当前以 Core 单测 + 构建验证为主。

## 9. 建议的短期迭代顺序

1. 增加 Step1/Step2 输出 schema 的版本化与错误分级（提升可维护性）。
2. 增加 Provider 连通性测试入口与失败诊断（提升可用性）。
3. 补充 UI 层最小回归测试（至少关键生成与导出路径）。
4. 设计并实现引用真实性校验服务（复用已存在字段）。

---

如果后续设计文档与代码发生冲突，请以代码行为为准，并在本文件更新“最后核对日期”。
