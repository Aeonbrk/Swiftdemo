# UI Architecture（2026-02-07）

## 目标

本项目 UI 以「信息架构清晰 + 交互层一致 + 编辑层可读」为优先级。
当前采用：

- 左侧：工作区路由（分组导航）
- 中央：路由详情内容（输入 / 预览 / 卡片 / 任务 / 引用 / 记录）
- 右侧：Provider Inspector（macOS）

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
- 路由状态管理（`PlanWorkspaceRoute`）
- 主操作区（Step1/Step2、状态提示、Provider 状态）
- macOS 三段布局 + iOS fallback

### 3) 内容层

- `demo/PlanInputTabs.swift`
- `demo/PlanInputEditors.swift`
- `demo/PlanInputActions.swift`

职责：
- 六个业务视图内容
- 卡片/任务编辑器
- 生成与导出动作

### 4) Provider 层

- `demo/ProviderSettingsView.swift`
- `demo/ProviderEditorView.swift`

职责：
- Provider 列表管理
- 激活切换
- Keychain API Key 写入与状态展示

### 5) 视觉语义层

- `demo/UIStyle.swift`
- `demo/AppGlass+Modifiers.swift`
- `demo/PlanUIComponents.swift`

职责：
- token（间距、圆角、列宽、状态色）
- 玻璃效果与按钮样式
- 通用组件（ActionBar / EmptyState / ExportMenu）

## Liquid Glass 使用边界

遵循「交互层玻璃、编辑层非玻璃」：

- 使用玻璃：顶部操作条、状态胶囊、关键动作按钮、路由侧栏容器
- 不使用玻璃：TextEditor、表单正文、长文本内容区
- 低版本回退：Material（不自定义 blur）

所有玻璃 API 都受可用性保护：
- `#available(iOS 26, macOS 26, *)`

## 平台差异策略

### macOS

- 主体工作流：侧栏路由 + 中央详情 + Inspector
- Provider 管理通过右侧 Inspector 打开/关闭
- 支持快捷键：
  - `⌘1...⌘6` 路由切换
  - `⌥⌘0` 工作区侧栏显隐
  - `⌥⌘9` Provider Inspector 显隐

### iOS

- 维持可编译与基础可用性
- 使用 `TabView` 作为 fallback
- 不启用 macOS 专属 Inspector 交互

## 设计原则

- MV 优先：状态就地管理，不新增 ViewModel
- 小组件组合：大视图拆分为职责清晰的子视图
- 先一致再增强：先保证结构统一，再做视觉细节迭代
