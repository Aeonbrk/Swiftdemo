# AGENTS.md (Project)

> 作用范围：`/Users/oian/Codes/Xcode/demo` 当前仓库
> 最后更新：2026-02-08

## 1) 入口规则（必须先做）

1. 开始任何任务前，先读取 `docs/CODEBASE_MAP.md`。
2. 文件定位优先使用 `docs/CODEBASE_MAP.md` 的 `Module Guide` 和 `Navigation Guide`。
3. 当代码结构发生变化（新增模块/目录职责变更）时，同步更新 `docs/CODEBASE_MAP.md`。

## 2) 架构边界

- `Core/`：领域模型、LLM client、Step1/Step2 pipeline、导出、持久化。
- `demo/`：SwiftUI 应用层、页面交互、路由与平台 UI。
- 业务规则优先放在 `Core`，避免把复杂领域逻辑堆到 `demo` 视图层。
- Provider 凭证只能通过 `demo/KeychainStore.swift` 走 Keychain，不得落盘明文。

## 3) 改动原则

- 保持向后兼容：未经明确要求，不改变现有数据模型含义和导出格式。
- 小步修改：优先最小可行改动，避免与任务无关的重构。
- 保持现有风格：遵循仓库当前 Swift/SwiftUI 代码组织方式。
- 行为变更时同步文档：至少检查 `README.md` 与 `docs/PROJECT_OVERVIEW.md` 是否需要更新。

## 4) 高风险区域（改动前先评估）

- `Core/Sources/Core/Pipeline/Step1OutputDecoder.swift`
- `Core/Sources/Core/Pipeline/Step2OutputDecoder.swift`
- `demo/PlanInputGenerationSupport.swift`
- `demo/ProviderSettingsView+Actions.swift`
- `demo/demoApp.swift`

以上位置涉及 JSON 解码容错、生成覆盖语义、Keychain 清理与启动期容器初始化，改动后必须补验证。

## 5) 验证命令（完成前执行）

```bash
swift test --package-path Core
xcodebuild -project demo.xcodeproj -scheme demo -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project demo.xcodeproj -scheme demo -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
swiftlint lint demo Core/Sources Core/Tests
```

如果受环境限制无法全跑，必须在交付说明中明确写出未执行项与风险。

## 6) 交付要求

- 回复默认使用中文（代码标识符保持英文）。
- 说明改动时给出可点击文件引用（如 `demo/PlanInputView.swift:42`）。
- 结论必须包含：改了什么、验证结果、剩余风险、自然下一步。

## 7) 多代理/并行任务约定

- 可并行且相互独立的任务（如“构建 + 测试”）应并行执行。
- 在所有子任务完成前，不输出“已完成”结论。
- 对同一文件的并发修改要避免冲突，必要时先拆分职责边界。
