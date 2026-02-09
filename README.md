# Learning Plan Demo

一个基于 SwiftUI + SwiftData 的学习计划整理应用：把长文本学习计划转成结构化计划、卡片（Flashcards）和任务（Todos），并在流程化工作区中完成生成、整理与执行。

## 这个项目解决什么问题

- 把“原始学习文本”稳定转换为可维护的学习资产（计划、卡片、任务）。
- 用四步流程降低上手门槛：输入素材 → 生成计划 → 整理产物 → 今日执行。
- 通过可替换 Provider（OpenAI-compatible）降低模型接入成本。

## 能力边界

### 已实现
- 多文档管理：创建、选择、删除 `PlanDocument`。
- 两步生成流程：
  - Step 1：生成 `planJSON`、`planMarkdown`、`claims`、`citations`。
  - Step 2：生成 `flashcards`、`todos`，支持 `replace` / `merge`。
- 流程引导与质量提示：
  - 顶部流程进度与下一步建议。
  - 执行可落地性检查（提示型，不阻断）。
- 今日执行一体化：
  - 任务筛选、状态推进、执行建议、任务详情、证据关联。
  - 高级抽屉：同步策略、待审核队列、自动化审计。
- Provider 管理（macOS）：预设导入、自定义、新增/删除、激活、连通性诊断。
- API Key 安全存储：仅使用 Keychain。
- 导出：
  - Flashcards → TSV / CSV
  - Todos → CSV（兼容 / 扩展）
- 核心模块单元测试（`Core` package）。

### 未实现（当前范围外）
- 引用真实性自动校验（当前只保留结构与状态字段）。
- `.apkg` 生成或 AnkiConnect 直连。
- 完整跨平台 Settings 体验（当前主要在 macOS）。

## 快速启动

### 环境要求
- Xcode（当前工程在 Xcode 17 系列工具链下验证）
- SwiftLint（代码规则校验）

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

### 可选：脚本启动 macOS App
```bash
./scripts/launch-mac.sh
```

## 目录说明

- `demo/`：应用层 UI 与交互逻辑
- `Core/`：可复用核心能力（模型、Pipeline、LLM、Execution、导出、持久化）
- `docs/PROJECT_OVERVIEW.md`：项目权威说明
- `docs/CODEBASE_MAP.md`：代码导航地图（入口、模块、关键数据流）
- `docs/perf/`：性能测量记录
- `.beads/`：本地 issue/任务追踪数据（git-backed）

## 关键流程（最短路径）

1. 在「输入素材」填写学习计划文本。
2. 在「生成计划」执行 Step 1。
3. 在「生成计划」执行 Step 2（可选 replace/merge）。
4. 在「整理产物」快速检查任务/卡片/引用/记录。
5. 自动进入「今日执行」开始推进任务。
6. 按需导出 TSV/CSV（macOS 走保存面板）。

## 常见问题

### 1) 生成时报错 `No active provider`
先在 Provider 设置里创建并激活一个 Provider。

### 2) 生成时报错 API key 缺失
在 Provider 编辑页保存 API key（写入 Keychain）。

### 3) Provider 可用但请求异常
打开 Provider Diagnostics 查看 HTTP 状态、延迟与建议文案。

### 4) 导出不可用
导出功能依赖 macOS 保存面板；非 macOS 平台会提示不支持。

## 维护说明

- 设计与实现说明以 `docs/PROJECT_OVERVIEW.md` 为准。
- 大范围代码变更后，请同步更新：
  - `README.md`
  - `docs/PROJECT_OVERVIEW.md`
  - `docs/CODEBASE_MAP.md`
