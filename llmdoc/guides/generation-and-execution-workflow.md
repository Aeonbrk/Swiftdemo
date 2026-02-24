# Guide: Generation and Execution Workflow

## Fast Path

1. Select or create a `PlanDocument`.
2. Fill raw study input in `inputMaterial`.
3. Run Step1 from `generatePlan`.
4. Run Step2 in replace or merge mode.
5. Review artifacts in `organizeArtifacts`.
6. Execute tasks in `todayExecution`.

## Quality and Repair

- Use quality panel signals to fix scheduling/detail gaps.
- Use recommendation cards to prioritize next actions.

## Auditing

- Generation actions append `GenerationRecord`.
- Automation/sync decisions append `AutomationAuditEntry`.
