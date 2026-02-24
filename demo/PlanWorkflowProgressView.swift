import Core
import SwiftUI

extension PlanInputView {
  var workflowProgressView: some View {
    let progress = WorkflowGuidanceEngine.progress(document: document)
    let stageCopy = workflowStageCopy(for: progress.recommendedStage)

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

        Text(stageCopy.purpose)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("完成标准：\(stageCopy.doneCriteria)")
          .font(.caption2)
          .foregroundStyle(.secondary)

        Button {
          navigateToWorkflowStage(progress.recommendedStage)
        } label: {
          Label(stageCopy.nextActionLabel, systemImage: "arrow.right.circle")
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

  func workflowStageCopy(for stage: WorkflowStage) -> WorkflowStageCopy {
    switch stage {
    case .inputMaterial:
      WorkflowStageCopy(
        purpose: "先补充学习目标、背景与限制，让生成结果更贴近你的真实场景。",
        doneCriteria: "输入内容清晰且不少于一段完整描述。",
        nextActionLabel: "去补充输入素材"
      )
    case .generatePlan:
      WorkflowStageCopy(
        purpose: "把原始输入转换成结构化计划，再生成可执行任务。",
        doneCriteria: "已完成 Step1（计划）并产出 Step2 任务。",
        nextActionLabel: "去生成计划"
      )
    case .organizeArtifacts:
      WorkflowStageCopy(
        purpose: "快速检查任务、卡片、引用是否完整，确认可以开始执行。",
        doneCriteria: "至少存在可执行任务，核心产物已过一遍。",
        nextActionLabel: "去整理产物"
      )
    case .todayExecution:
      WorkflowStageCopy(
        purpose: "聚焦今天最重要的事项，持续推进并留痕执行证据。",
        doneCriteria: "至少启动一个任务并更新状态/时间。",
        nextActionLabel: "去今日执行"
      )
    }
  }
}

struct WorkflowStageCopy: Sendable {
  let purpose: String
  let doneCriteria: String
  let nextActionLabel: String
}
