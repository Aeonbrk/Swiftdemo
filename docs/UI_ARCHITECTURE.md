# UI Architecture（2026-02-09）

## 目标

本项目 UI 以「3 分钟上手 + 流程清晰 + 操作闭环」为优先级。
当前 macOS 采用四步流程化工作区：

- 左侧：四步主导航（输入素材 / 生成计划 / 整理产物 / 今日执行）
- 中央：当前流程步骤内容
- 右侧：Provider Inspector（按需打开，默认不打扰）

## 架构分层

### 1) 壳层

- `demo/ContentView.swift`
- 职责：文档列表、搜索、新建/删除、详情容器。

### 2) 工作区层

- `demo/PlanInputView.swift`
- `demo/PlanWorkspaceRoute.swift`
- `demo/PlanWorkspaceSidebarView.swift`
- `demo/PlanWorkspaceDetailView.swift`

职责：
- 四步路由状态管理（`PlanWorkspaceRoute`）
- macOS 三段布局 + iOS 四标签 fallback
- 统一挂载流程进度与状态提示

### 3) 内容层

- `demo/PlanInputTabs.swift`
- `demo/PlanInputExecutionTab.swift`
- `demo/PlanInputExecutionRows.swift`
- `demo/PlanInputExecutionAutomation.swift`
- `demo/PlanInputEditors.swift`
- `demo/PlanInputActions.swift`
- `demo/PlanWorkflowProgressView.swift`

职责：
- 输入素材、生成计划、整理产物、今日执行四步内容
- 今日执行内完成任务推进、建议采纳、详情编辑、证据关联
- 高级执行能力（同步策略/待审核/审计）折叠展示

### 4) Core 引导与质量反馈层

- `Core/Sources/Core/Execution/WorkflowGuidanceEngine.swift`

职责：
- 计算流程阶段建议（`WorkflowProgressSnapshot`）
- 输出执行质量提示（`WorkflowQualityIssue`，非阻断）

### 5) Provider 层

- `demo/ProviderSettingsView.swift`
- `demo/ProviderEditorView.swift`

职责：
- Provider 列表管理与激活
- Keychain API Key 写入与状态展示
- 连通性诊断

## 交互策略

### 四步流程

1. **输入素材**：填写目标和原始输入。
2. **生成计划**：触发 Step 1/Step 2（高级参数折叠）。
3. **整理产物**：默认总览，`更多` 查看卡片/引用/记录。
4. **今日执行**：任务列表 + 推荐 + 详情 + 高级抽屉。

### 关键行为

- Step 2 成功后自动跳转到「今日执行」。
- 质量反馈为提示型，不阻断用户继续操作。
- Provider 面板默认收起，仅在需要配置时主动打开。

## 平台差异策略

### macOS

- 主体工作流：侧栏四步导航 + 中央详情 + Inspector。
- 快捷键：`⌘1...⌘4` 对应四步主流程。

### iOS

- 维持可编译与基础可用。
- 使用四标签 `TabView` 对齐流程语义。
- 不启用 macOS 专属 Inspector 交互。

## 设计原则

- 流程优先：先告诉用户“现在做什么、下一步做什么”。
- 默认简洁：高级策略折叠，按需展开。
- 同页闭环：执行相关操作尽量在一个页面内完成。
