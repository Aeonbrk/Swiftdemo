# Project Overview

This document is a code-aligned summary of architecture, workflow, capability boundaries, and verification policy.

## Project Positioning

The app converts user-provided learning-plan text into editable, executable, and exportable outputs using a two-step LLM workflow.

Core goals:

- Step 1: generate structured plan data (`planJSON`, `planMarkdown`) and evidence (`claims`, `citations`).
- Step 2: derive `flashcards` and `todos`.
- Complete the loop in one workspace: input, generate, organize, execute.

## Current Information Architecture (macOS)

Main workflow stages:

1. `inputMaterial`
2. `generatePlan`
3. `organizeArtifacts`
4. `todayExecution`

Key behavior:

- Step 2 success auto-routes to `todayExecution`.
- Artifact details (cards/citations/records) are accessible from `organizeArtifacts`.
- Provider inspector stays out of the way by default and opens on demand from toolbar.

## Architecture Snapshot

### Module split

- `Core`: models, LLM client, Step1/Step2 pipelines, execution engines, exporters, container factory.
- `demo`: document shell, route-driven workspace, provider management, keychain integration.

### Key entrypoints

- `demo/demoApp.swift`
- `demo/ContentView.swift`
- `demo/PlanInputView.swift`
- `demo/PlanWorkspaceRoute.swift`
- `demo/PlanInputExecutionTab.swift`
- `demo/PlanWorkflowProgressView.swift`
- `Core/Sources/Core/Execution/WorkflowGuidanceEngine.swift`

## Capability Matrix

| Capability | Status |
| --- | --- |
| Multi-document management | Implemented |
| Step 1 generation (plan + evidence) | Implemented |
| Step 2 generation (cards + todos) | Implemented |
| Step 2 replace/merge | Implemented |
| Workflow guidance and next-step hints | Implemented |
| Execution quality hints (non-blocking) | Implemented |
| Unified execution workspace | Implemented |
| Advanced sync/audit drawer | Implemented |
| Provider management + Keychain | Implemented (macOS-first) |
| Citation authenticity verification | Not implemented |

## Runtime Workflow

1. Confirm provider from toolbar.
2. Fill raw study text in `inputMaterial`.
3. Run Step 1 in `generatePlan`.
4. Run Step 2 (`replace` or `merge`).
5. App auto-routes to `todayExecution`.
6. Filter todos, apply recommendations, update status/details/evidence.
7. Review and export artifacts from `organizeArtifacts`.

## Build and Validation

```bash
swift test --package-path Core
xcodebuild -project demo.xcodeproj -scheme demo -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project demo.xcodeproj -scheme demo -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
swiftlint lint demo Core/Sources Core/Tests
```

Deterministic local wrapper (recommended):

```bash
./scripts/verify-local.sh
```

This wrapper sets a repo-local temp dir and writes logs to `.tmp/verify-logs/`.

## Known Boundaries

- Provider settings UX is macOS-first.
- Quality feedback is advisory and non-blocking.
- UI regression relies mostly on build verification and Core tests.
