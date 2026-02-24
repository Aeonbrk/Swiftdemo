# AGENTS.md (Project)

> Scope: `/Users/oian/Codes/Xcode/demo` repository
> Last updated: 2026-02-24

## 1) Entry Rules (Must Do First)

1. Read `llmdoc/index.md` before starting any task.
2. Use `llmdoc/reference/CODEBASE_MAP.md` as the primary navigation map for module boundaries and file targeting.
3. When module responsibilities, entrypoints, or directory ownership change, update `llmdoc/reference/CODEBASE_MAP.md` in the same change set.

## 2) Architecture Boundaries

- `Core/`: domain models, LLM client, Step1/Step2 pipelines, execution intelligence, export, persistence.
- `demo/`: SwiftUI app layer, interaction flow, route/state orchestration, platform-specific UI.
- Keep domain logic in `Core`; avoid pushing complex domain rules into view-layer files.
- Provider credentials must go through `demo/KeychainStore.swift`; never persist plaintext credentials.

## 3) Change Principles

- Preserve backward compatibility unless explicitly requested.
- Prefer minimal, low-risk edits over broad refactors.
- Follow current Swift/SwiftUI project patterns.
- On behavior changes, update at least:
  - `README.md`
  - `llmdoc/overview/project-overview.md`
  - `llmdoc/reference/CODEBASE_MAP.md`

## 4) High-Risk Areas (Assess Before Editing)

- `Core/Sources/Core/Pipeline/Step1OutputDecoder.swift`
- `Core/Sources/Core/Pipeline/Step2OutputDecoder.swift`
- `demo/PlanInputGenerationSupport.swift`
- `demo/ProviderSettingsView+Actions.swift`
- `demo/demoApp.swift`

These files affect JSON decoding tolerance, merge semantics, credential cleanup, and startup container initialization. Changes require focused verification.

## 5) Required Verification Commands

```bash
swift test --package-path Core
xcodebuild -project demo.xcodeproj -scheme demo -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project demo.xcodeproj -scheme demo -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
swiftlint lint demo Core/Sources Core/Tests
```

If environment constraints block execution, list skipped commands and resulting risk explicitly in handoff notes.

## 6) Delivery Requirements

- Default repository delivery language is English.
- Include clickable file references (for example: `demo/PlanInputView.swift:42`).
- Every conclusion must state:
  - what changed
  - verification results
  - remaining risks
  - natural next step

## 7) Multi-Agent and Parallel Work Convention

- Run independent tasks in parallel when safe (for example, build + tests).
- Do not claim completion until all subtasks are complete.
- Avoid concurrent edits to the same file; split ownership boundaries first.

## 8) Documentation Workflow Rule

- `llmdoc/` is the active documentation system in this repository.
- `llmdoc/reference/CODEBASE_MAP.md` is the canonical structural map for agent navigation.
- Keep `llmdoc/index.md` and linked documents synchronized with current code behavior.
