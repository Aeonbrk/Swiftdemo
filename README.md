# Learning Plan Demo

一个基于 SwiftUI + SwiftData 的学习计划整理应用：把长文本学习计划转成结构化计划、闪卡（Flashcards）和待办（Todos），并支持本地编辑与导出。

## 能力边界

### 已实现
- 多文档管理：创建、选择、删除 `PlanDocument`。
- 两步生成流程：
  - Step 1：生成 `planJSON`、`planMarkdown`、`claims`、`citations`。
  - Step 2：从计划派生 `flashcards`、`todos`。
- Provider 管理（macOS）：预设导入、自定义、新增/删除、激活。
- API Key 安全存储：仅使用 Keychain。
- 导出：
  - Flashcards → TSV / CSV
  - Todos → CSV
- Todo 语义字段：`status`、`priority`、`completedAt`（编辑器使用受控选择，不再依赖自由文本状态）。
- 核心模块单元测试（Core package）。

### 未实现
- 引用真实性自动校验（仅保留状态字段）。
- `.apkg` 生成或 AnkiConnect 直连。
- 完整跨平台 Settings 体验（当前 Settings 仅 macOS）。

## 快速启动

### 环境要求
- Xcode（当前工程已在 Xcode 17 系列工具链下验证）
- SwiftLint（用于代码规则校验）

### 构建与测试
```bash
swift test --package-path Core
xcodebuild -project demo.xcodeproj -scheme demo -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project demo.xcodeproj -scheme demo -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

### 代码质量检查
```bash
swiftlint lint demo Core/Sources Core/Tests
```

## 目录说明

- `demo/`：应用层 UI 与交互逻辑
- `Core/`：可复用核心能力（模型、Pipeline、LLM、导出、持久化）
- `docs/PROJECT_OVERVIEW.md`：当前项目的权威说明文档

## 关键流程

1. 在 Input 页输入学习计划文本。
2. 执行 Step 1 生成结构化计划与引用。
3. 执行 Step 2 生成 Flashcards 与 Todos。
4. 在 Cards/Todos 标签页编辑内容。
5. 通过导出按钮导出 TSV/CSV 文件（macOS 走保存面板）。

## 常见问题

### 1) 生成时报错 “No active provider”
先在 Settings 中创建并激活一个 Provider。

### 2) 生成时报错 API key 缺失
在 Settings 的 Provider 编辑页保存 API key（写入 Keychain）。

### 3) 网络请求被系统拒绝
在 macOS Target 的 App Sandbox 中启用 `Outgoing Connections (Client)`。

### 4) 导出不可用
导出功能依赖 macOS 保存面板；非 macOS 平台会提示不支持。

## 维护说明

- 设计与实现说明以 `docs/PROJECT_OVERVIEW.md` 为准。
- 当代码行为变化时，请同步更新 README 与 `PROJECT_OVERVIEW`。
