# Coding Conventions

## General

- Keep domain logic in `Core`; keep UI orchestration in `demo`.
- Preserve backward compatibility unless explicitly requested.
- Prefer minimal, focused changes over broad refactors.

## Swift/SwiftUI

- Follow existing file split patterns (`PlanInput*`, `ProviderSettingsView*`).
- Use explicit semantic helper functions for workflow actions.
- Keep provider credentials out of persistent model fields.

## Documentation

- Update `README.md` and `llmdoc/overview/project-overview.md` on behavior changes.
- Update `llmdoc/reference/CODEBASE_MAP.md` when module boundaries or entrypoints change.
