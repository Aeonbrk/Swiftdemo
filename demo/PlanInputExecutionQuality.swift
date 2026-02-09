import Core
import SwiftUI

extension PlanInputView {
  var executionQualityIssuePanel: some View {
    let issues = executionQualityIssues
    return Group {
      if !issues.isEmpty {
        AppPanelCard {
          VStack(alignment: .leading, spacing: 10) {
            Text("执行质量提示")
              .font(.headline)

            ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
              HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundStyle(UIStyle.warningStatusColor)

                VStack(alignment: .leading, spacing: 4) {
                  Text(issue.title)
                    .font(.subheadline.weight(.semibold))
                  Text(issue.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                }

                Spacer(minLength: UIStyle.compactSpacing)

                Button(qualityRepairTitle(for: issue.repairAction)) {
                  applyQualityRepairAction(issue.repairAction)
                }
                .appSecondaryActionButtonStyle()
              }
              .padding(8)
              .appChipGlass()
            }
          }
        }
      }
    }
  }

  private var executionQualityIssues: [WorkflowQualityIssue] {
    WorkflowGuidanceEngine.executionQualityIssues(todos: document.todos)
  }

  private func qualityRepairTitle(for action: WorkflowQualityRepairAction) -> String {
    switch action {
    case .openGeneratePlan:
      "去生成计划"
    case .scheduleHighPriorityTodos:
      "优先补时间"
    case .completeBlockedTodoDetail:
      "补充阻塞原因"
    case .scheduleUnplannedTodos:
      "批量安排"
    }
  }

  private func applyQualityRepairAction(_ action: WorkflowQualityRepairAction) {
    switch action {
    case .openGeneratePlan:
      navigateToWorkflowStage(.generatePlan)
    case .scheduleHighPriorityTodos:
      executionFilter = .today
      focusTodoNeedingSchedule()
    case .completeBlockedTodoDetail:
      executionFilter = .blocked
      focusBlockedTodoMissingDetail()
    case .scheduleUnplannedTodos:
      executionFilter = .today
      focusTodoNeedingSchedule()
    }
  }

  private func focusTodoNeedingSchedule() {
    guard
      let todo = document.todos.first(where: {
        $0.status != .done
          && $0.dueAt == nil
          && $0.scheduledAt == nil
      })
    else { return }

    selectedTodoID = todo.id
  }

  private func focusBlockedTodoMissingDetail() {
    guard
      let todo = document.todos.first(where: {
        $0.status == .blocked
          && $0.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      })
    else { return }

    selectedTodoID = todo.id
  }
}
