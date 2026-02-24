# Core Pipeline and Data Flow

## Generation Pipeline

1. UI builds request context from active provider.
2. `Step1Pipeline.run` generates outline JSON/markdown + claims/citations.
3. `Step2Pipeline.run` generates flashcards and todos.
4. `Step2OutputMerger.merge` applies replace or merge semantics.
5. UI writes mapped entities into `PlanDocument` graph.

## Execution Pipeline

- `ExecutionSuggestionEngine.recommendations` ranks actionable tasks.
- `WorkflowGuidanceEngine.executionQualityIssues` reports non-blocking quality warnings.
- `ExternalTaskMapping` + `SyncConflictResolver` mediate remote sync.

## Persistence Boundary

`CoreModelContainer.make` defines the canonical model registration list and the in-memory/on-disk container mode.
