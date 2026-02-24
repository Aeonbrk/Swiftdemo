# UI Switching Metrics (2026-02-09)

## Scope

This benchmark quantified two optimization axes for macOS UI switching:

1. Route switching behavior in `PlanWorkspaceDetailView` (remove forced rebuild path, keep legacy toggle).
2. Document timestamp write policy (`PlanDocument.updatedAt` immediate write vs debounced write).

Environment variables used in runs:

- `DEMO_PERF_AUTOMATION`
- `DEMO_PERF_USE_LEGACY_ROUTE_SWITCH`
- `DEMO_PERF_USE_IMMEDIATE_UPDATED_AT`

Sampling was collected with `xctrace` SwiftUI template and parsed from:

- `SwiftUIFilteredUpdates` (`View Body Updates` table)
- `hitches`

## Method

Three comparison groups:

- `legacy_immediate`: legacy route switch + immediate `updatedAt`
- `legacy_debounced`: legacy route switch + debounced `updatedAt`
- `optimized_debounced`: optimized route switch + debounced `updatedAt`

Intermediate artifacts were stored under `tmp/perf/*` during the original run.

## Result Summary

- Debounced `updatedAt` delivered clear total-duration improvement (about 6%).
- Route-switch optimization significantly reduced `View Body` update counts (about 20%).
- `hitches` were zero in the 6-second automation window for all runs.

## Notes

- This was the first reproducible automation baseline; absolute values vary with machine load.
- Initial export for `legacy_immediate` hit the `Other Updates` table, then parsing was corrected to the `View Body Updates` index.
- Parsed metrics script output was written to `tmp/perf/metrics-body.json` in the original benchmark session.
