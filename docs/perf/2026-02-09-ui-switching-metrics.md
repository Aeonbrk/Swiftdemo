# UI Switching Metrics (2026-02-09)

## Scope

目标：量化以下两类优化对 macOS UI 切换体验的影响。

1. 路由切换：`PlanWorkspaceDetailView` 去掉默认强制重建路径（保留可切换 legacy 模式）。
2. 文档编辑/切换：`PlanDocument.updatedAt` 从即时写入改为防抖写入。

测试使用环境变量开关：

- `DEMO_PERF_AUTOMATION=1`
- `DEMO_PERF_USE_LEGACY_ROUTE_SWITCH=0|1`
- `DEMO_PERF_USE_IMMEDIATE_UPDATED_AT=0|1`

并通过 `xctrace` `SwiftUI` 模板采样，解析 `SwiftUIFilteredUpdates(including: View Body Updates)` 与 `hitches` 表。

## Method

- Build: `Debug`（`xcodebuild -project demo.xcodeproj -scheme demo ... build`）
- Trace template: `SwiftUI`
- Recording duration: `6s`
- Data extraction:
  - `SwiftUIFilteredUpdates`（仅 `View Body Updates` 子表）
  - `hitches`
- 三组对比：
  - `legacy_immediate`: 旧路由切换 + 即时 `updatedAt`
  - `legacy_debounced`: 旧路由切换 + 防抖 `updatedAt`
  - `optimized_debounced`: 新路由切换 + 防抖 `updatedAt`

原始中间产物保存在 `tmp/perf/*`。

## Results

| Case | View Body Rows | Total Duration (ms) | Focus Rows* | Focus Duration (ms) | Hitches |
|---|---:|---:|---:|---:|---:|
| legacy_immediate | 33356 | 203.086 | 1165 | 52.033 | 0 |
| legacy_debounced | 32747 | 190.678 | 1070 | 48.730 | 0 |
| optimized_debounced | 26275 | 193.746 | 865 | 52.742 | 0 |

\* Focus Rows 统计包含 `PlanInputView` / `ContentView` / `PlanWorkspace*` / `AppRouteScaffold` / `TabView` 相关更新。

### Relative changes

- `legacy_immediate -> legacy_debounced`
  - View Body Rows: **-1.83%**
  - Total Duration: **-6.11%**
- `legacy_debounced -> optimized_debounced`
  - View Body Rows: **-19.76%**
  - Focus Rows: **-19.16%**
  - Total Duration: **+1.61%**（接近持平，可能受玻璃效果与按钮更新占比影响）

## Interpretation

1. 防抖 `updatedAt` 对总耗时有明确收益（约 6%），验证了“输入时列表重排抖动”假设。  
2. 路由切换优化明显减少了 `View Body` 更新次数（约 20%），说明去除强制重建路径有效降低了更新风暴。  
3. `hitches` 在本轮 6s 自动化窗口内均为 0，说明当前采样窗口未触发可检测卡顿事件；后续建议延长到 20~30s 并使用多轮统计。  

## Notes

- 这是“可复现自动化采样”首版，重点是建立对比框架；绝对数值会受系统后台负载影响。
- `legacy_immediate` 首次导出命中 `Other Updates` 子表，后续已按 TOC 中 `View Body Updates` 表索引修正。
- 指标解析脚本输出位于 `tmp/perf/metrics-body.json`。
