# App Workspace and Navigation

## Goal

Optimize for fast onboarding, clear workflow transitions, and closed-loop execution.

The macOS workspace uses four route-driven stages:

- Sidebar navigation: `inputMaterial`, `generatePlan`, `organizeArtifacts`, `todayExecution`
- Center detail: active stage content
- Top toolbar: global provider access
- Optional inspector: provider settings and diagnostics

## Layered Architecture

### 1) App shell

- File: `demo/ContentView.swift`
- Responsibilities:
  - Document list/search/create/delete.
  - Host detail container.
  - Own global provider inspector state.

### 2) Workspace layer

- Files: `demo/PlanInputView.swift`, `demo/PlanWorkspaceRoute.swift`, `demo/PlanWorkspaceSidebarView.swift`, `demo/PlanWorkspaceDetailView.swift`
- Responsibilities:
  - Route state and keyboard shortcuts (`cmd+1` to `cmd+4` on macOS).
  - macOS route layout and iOS tab fallback.
  - Unified progress and stage transitions.

### 3) Stage content layer

- Files: `demo/PlanInputTabs.swift`, `demo/PlanInputExecutionTab.swift`, `demo/PlanInputExecutionSurface.swift`
- Responsibilities:
  - Input/generation/organization/execution stage content.
  - Recommendation-driven execution actions.
  - Evidence and details editing flows.

### 4) Guidance and quality layer

- Files: `Core/Sources/Core/Execution/WorkflowGuidanceEngine.swift`, `demo/PlanInputExecutionQuality.swift`
- Responsibilities:
  - Compute recommended stage and next action.
  - Emit execution quality issues and repair actions (non-blocking).

### 5) Provider layer

- Files: `demo/ProviderSettingsView.swift`, `demo/ProviderEditorView.swift`, `demo/KeychainStore.swift`
- Responsibilities:
  - Provider CRUD and activation.
  - API key lifecycle through Keychain.
  - Connectivity diagnostics.

## Interaction Policy

1. `inputMaterial`: capture raw learning input.
2. `generatePlan`: execute Step1 and Step2 with advanced options collapsed by default.
3. `organizeArtifacts`: review overview and deep details.
4. `todayExecution`: execute, prioritize, update, and sync todos.

Key behavior guarantees:

- Step 2 success automatically routes to `todayExecution`.
- Quality feedback does not block user actions.
- Provider controls remain globally accessible from toolbar.

## Platform Strategy

- macOS: full route workspace + inspector model.
- iOS: semantic parity via tab model with reduced desktop-specific affordances.
