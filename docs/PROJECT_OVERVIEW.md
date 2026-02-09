# Project Overview: Learning Plan to Cards & Todos

> 文档用途：提供“以代码为准”的项目说明，覆盖架构、流程、能力边界与验证方式。
> 最后核对日期：2026-02-09

## 1. 项目定位

这是一个原生 SwiftUI 应用：把用户输入的学习计划文本通过两阶段 LLM 流程，转换为可编辑、可执行、可导出的学习产物。

核心目标：
- Step 1：生成结构化计划（`planJSON` + `planMarkdown`）及证据（`claims` + `citations`）。
- Step 2：派生 `flashcards` 与 `todos`。
- 在统一工作区中完成输入、生成、整理、执行闭环。

## 2. 当前信息架构（macOS）

工作区采用四步主流程：
1. 输入素材
2. 生成计划
3. 整理产物
4. 今日执行

关键变化：
- 旧“任务/执行”分离改为「今日执行」一体化页面。
- 卡片/引用/记录下沉到「整理产物」的 `更多` 入口。
- Step 2 成功后自动跳转「今日执行」。
- Provider Inspector 默认收起，按需打开。

## 3. 架构现状（以代码为准）

### 3.1 模块分层

- `Core` Swift Package：模型、LLM client、Step1/Step2 pipeline、执行引擎、导出器、容器工厂。
- `demo` App：文档列表、流程化工作区、Provider 管理、Keychain 集成。

### 3.2 关键入口

- App 入口：`demo/demoApp.swift`
- 工作区根视图：`demo/PlanInputView.swift`
- 四步路由：`demo/PlanWorkspaceRoute.swift`
- 执行页：`demo/PlanInputExecutionTab.swift`
- 流程引导：`demo/PlanWorkflowProgressView.swift`
- 质量反馈引擎：`Core/Sources/Core/Execution/WorkflowGuidanceEngine.swift`

## 4. 能力完成度

| 能力 | 当前状态 |
|---|---|
| 多文档管理 | 已实现 |
| Step 1 生成（计划+证据） | 已实现 |
| Step 2 生成（卡片+任务） | 已实现 |
| Step 2 replace/merge | 已实现 |
| 流程进度与下一步引导 | 已实现 |
| 执行质量提示（非阻断） | 已实现 |
| 任务执行一体化（列表+详情+动作） | 已实现 |
| 高级同步/审计折叠能力 | 已实现 |
| Provider 管理 + Keychain | 已实现（macOS 主路径） |
| 引用真实性自动校验 | 未实现（仅预留字段） |

## 5. 运行流程（当前实现）

1. 在「输入素材」填写原始学习文本。
2. 在「生成计划」执行 Step 1。
3. 在「生成计划」执行 Step 2（支持 replace/merge）。
4. Step 2 成功后自动进入「今日执行」。
5. 在「今日执行」筛选任务、采纳建议、更新状态、补充详情与证据。
6. 在「整理产物」查看卡片/引用/记录并导出。

## 6. 构建与测试命令

```bash
swift test --package-path Core
xcodebuild -project demo.xcodeproj -scheme demo -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project demo.xcodeproj -scheme demo -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
swiftlint lint demo Core/Sources Core/Tests
```

## 7. 已知边界

- Provider 设置体验以 macOS 为主，iOS 以可编译与基础可用为主。
- 质量反馈当前是提示型 MVP，不阻断执行。
- UI 层暂无自动化测试，主要依赖 Core 单测 + 双平台构建验证。

## 8. 后续建议

1. 继续拆分大文件（`PlanInputExecutionTab.swift`、`PlanInputTabs.swift`），降低维护成本。
2. 引入最小 UI 回归测试，覆盖四步主流程。
3. 在质量反馈中增加可配置阈值与忽略策略。
4. 设计并实现引用真实性自动校验。
