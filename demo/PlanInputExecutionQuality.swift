import Core
import SwiftUI

extension PlanInputView {
  private static let qualityPreviewLimit = 2

  var executionQualityIssuePanel: some View {
    let issues = executionQualityIssues
    let previewIssues = Array(issues.prefix(Self.qualityPreviewLimit))

    return Group {
      if !issues.isEmpty {
        AppPanelCard {
          VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: UIStyle.compactSpacing) {
              Text("执行质量提示")
                .font(.headline)

              Spacer(minLength: UIStyle.compactSpacing)

              if issues.count > Self.qualityPreviewLimit {
                Button {
                  withAnimation(.snappy(duration: 0.2)) {
                    isExecutionQualityExpanded.toggle()
                  }
                } label: {
                  Label(
                    isExecutionQualityExpanded ? "收起全部" : "查看全部（\(issues.count)）",
                    systemImage: isExecutionQualityExpanded ? "chevron.up" : "chevron.down"
                  )
                }
                .appSecondaryActionButtonStyle()
              }
            }

            ForEach(
              displayedQualityIssues(issues: issues, previewIssues: previewIssues),
              id: \.kind
            ) { issue in
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

            if !isExecutionQualityExpanded && issues.count > Self.qualityPreviewLimit {
              Text("仅展示高影响问题，展开可查看完整列表。")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }

  private func displayedQualityIssues(
    issues: [WorkflowQualityIssue],
    previewIssues: [WorkflowQualityIssue]
  ) -> [WorkflowQualityIssue] {
    if isExecutionQualityExpanded {
      return issues
    }
    return previewIssues
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
