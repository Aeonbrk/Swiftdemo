# Learning Plan Demo

A SwiftUI + SwiftData learning-planning app that converts long-form study text into structured assets (plan, flashcards, and todos) inside a guided workflow.

## What This Project Solves

- Converts raw study text into maintainable learning artifacts.
- Provides a 4-stage workflow to reduce onboarding friction: `inputMaterial` -> `generatePlan` -> `organizeArtifacts` -> `todayExecution`.
- Supports pluggable OpenAI-compatible providers for lower integration cost.

## Capability Boundaries

### Implemented

- Multi-document management: create/select/delete `PlanDocument`.
- Two-stage generation:
  - Step 1: produce `planJSON`, `planMarkdown`, `claims`, `citations`.
  - Step 2: produce `flashcards`, `todos` with `replace` / `merge` modes.
- Workflow guidance and quality hints:
  - Top workflow progress and next-step recommendation.
  - Execution quality checks (non-blocking hints).
- Unified execution workspace:
  - Todo filtering, status updates, recommendations, details, evidence links.
  - Advanced drawer for sync policy, pending review queue, and automation audit.
- Provider management (macOS): presets, custom providers, add/delete/activate, diagnostics.
- API key handling via Keychain only.
- Export:
  - Flashcards -> TSV / CSV
  - Todos -> CSV (legacy / extended)
- Core unit tests in the `Core` Swift package.

### Not Implemented (Out of Scope)

- Automatic citation authenticity verification.
- `.apkg` generation or direct AnkiConnect integration.
- Fully symmetric cross-platform settings UX (macOS-first currently).

## Quick Start

### Requirements

- Xcode (project validated on Xcode 17 toolchain line)
- SwiftLint

### Build and Test

```bash
swift test --package-path Core
xcodebuild -project demo.xcodeproj -scheme demo -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project demo.xcodeproj -scheme demo -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

### Lint

```bash
swiftlint lint demo Core/Sources Core/Tests
```

### Deterministic Local Verification

Use the repo wrapper to run all required checks with a repo-local temp directory and per-step logs:

```bash
./scripts/verify-local.sh
```

Logs are written to `.tmp/verify-logs/`.

### Optional: Launch macOS App Script

```bash
./scripts/launch-mac.sh
```

## Repository Layout

- `demo/`: app-layer UI and interaction logic.
- `Core/`: reusable core capabilities (models, pipelines, LLM client, execution, export, persistence).
- `llmdoc/`: agent-oriented documentation and structural map.
- `.beads/`: local git-backed issue/task tracking data.

## Primary Workflow (Shortest Path)

1. Confirm provider from the top toolbar.
2. Fill study text in `inputMaterial`.
3. Run Step 1 in `generatePlan`.
4. Run Step 2 in `generatePlan` (`replace` or `merge`).
5. Review artifacts in `organizeArtifacts`.
6. Continue work in `todayExecution` (auto-routed after successful Step 2).
7. Export TSV/CSV as needed.

## FAQ

### `No active provider` during generation

Open provider settings from the toolbar and activate a provider.

### Missing API key error

Save API key in provider editor (stored in Keychain).

### Provider reachable but request fails

Open diagnostics and inspect HTTP status, latency, and error summary.

### Export is unavailable

Export relies on macOS save panel; non-macOS platforms show unsupported feedback.

## Maintenance Notes

- `llmdoc/reference/CODEBASE_MAP.md` is the canonical navigation map.
- After broad changes, update `README.md` and relevant `llmdoc/*` docs together.
