import Core
import SwiftUI

extension PlanInputView {
  var workflowProgressView: some View {
    let progress = WorkflowGuidanceEngine.progress(document: document)

    return AppPanelCard {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        HStack(alignment: .firstTextBaseline) {
          Text("流程进度")
            .font(.headline)

          Spacer(minLength: UIStyle.compactSpacing)

          Text("\(progress.completedStageCount)/4")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 6) {
          ForEach(Array(PlanWorkspaceRoute.allCases.enumerated()), id: \.element) { index, _ in
            Circle()
              .fill(index < progress.completedStageCount ? Color.accentColor : Color.secondary.opacity(0.25))
              .frame(width: 8, height: 8)
          }
        }

        Text(stageGuidanceText(for: progress.recommendedStage))
          .font(.caption)
          .foregroundStyle(.secondary)

        Button {
          navigateToWorkflowStage(progress.recommendedStage)
        } label: {
          Label(nextActionTitle(for: progress.recommendedStage), systemImage: "arrow.right.circle")
        }
        .appSecondaryActionButtonStyle()
      }
    }
  }

  func navigateToWorkflowStage(_ stage: WorkflowStage) {
    guard let route = workflowRoute(for: stage) else { return }
    #if os(macOS)
      selectedRoute = route
    #else
      selectedMainTab = workflowTab(for: route)
    #endif
  }

  private func workflowRoute(for stage: WorkflowStage) -> PlanWorkspaceRoute? {
    switch stage {
    case .inputMaterial:
      .inputMaterial
    case .generatePlan:
      .generatePlan
    case .organizeArtifacts:
      .organizeArtifacts
    case .todayExecution:
      .todayExecution
    }
  }

  private func workflowTab(for route: PlanWorkspaceRoute) -> PlanInputMainTab {
    switch route {
    case .inputMaterial:
      .inputMaterial
    case .generatePlan:
      .generatePlan
    case .organizeArtifacts:
      .organizeArtifacts
    case .todayExecution:
      .todayExecution
    }
  }

  private func stageGuidanceText(for stage: WorkflowStage) -> String {
    switch stage {
    case .inputMaterial:
      "先补充学习目标与输入素材。"
    case .generatePlan:
      "下一步生成结构化计划与任务。"
    case .organizeArtifacts:
      "检查任务、卡片与引用后再执行。"
    case .todayExecution:
      "当前可以开始推进今日任务。"
    }
  }

  private func nextActionTitle(for stage: WorkflowStage) -> String {
    switch stage {
    case .inputMaterial:
      "去补充输入素材"
    case .generatePlan:
      "去生成计划"
    case .organizeArtifacts:
      "去整理产物"
    case .todayExecution:
      "去今日执行"
    }
  }
}
