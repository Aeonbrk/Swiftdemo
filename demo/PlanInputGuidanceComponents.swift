import Core
import SwiftUI

extension PlanInputView {
  var generatePrimaryActionLabel: String {
    document.outline == nil ? "生成计划（Step 1）" : "生成任务（Step 2）"
  }

  var generatePrimaryActionSymbol: String {
    document.outline == nil ? "sparkles" : "wand.and.stars"
  }

  var canRunStep1: Bool {
    document.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }

  var isGeneratePrimaryActionDisabled: Bool {
    if isGenerating {
      return true
    }

    if document.outline == nil {
      return canRunStep1 == false
    }

    return false
  }

  func performGeneratePrimaryAction() {
    if document.outline == nil {
      generateStep1()
      return
    }

    generateStep2()
  }

  var workflowOnboardingBanner: some View {
    AppPanelCard(surface: .outlined) {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        HStack(alignment: .firstTextBaseline, spacing: UIStyle.compactSpacing) {
          Label("快速上手", systemImage: "flag.checkered")
            .font(.headline)

          Spacer(minLength: UIStyle.compactSpacing)

          Button("收起") {
            withAnimation(.snappy(duration: 0.2)) {
              isWorkflowOnboardingPresented = false
            }
          }
          .appSecondaryActionButtonStyle()
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("1. 输入素材：写清目标、背景、限制。")
          Text("2. 生成计划：先 Step 1，再 Step 2 产出任务。")
          Text("3. 今日执行：启动任务并持续更新状态。")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }

  func nowNextGuideCard(
    stage: WorkflowStage,
    nextActionLabel: String? = nil,
    action: @escaping () -> Void
  ) -> some View {
    let stageCopy = workflowStageCopy(for: stage)

    return AppPanelCard(surface: .outlined) {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        HStack(alignment: .firstTextBaseline, spacing: UIStyle.compactSpacing) {
          Text("现在做什么")
            .font(.headline)

          Spacer(minLength: UIStyle.compactSpacing)

          Button {
            withAnimation(.snappy(duration: 0.2)) {
              isWorkflowOnboardingPresented = true
            }
          } label: {
            Label("查看引导", systemImage: "questionmark.circle")
          }
          .appSecondaryActionButtonStyle()
        }

        Text(stageCopy.purpose)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("完成标准：\(stageCopy.doneCriteria)")
          .font(.caption2)
          .foregroundStyle(.secondary)

        Button {
          action()
        } label: {
          Label(nextActionLabel ?? stageCopy.nextActionLabel, systemImage: "arrow.right.circle")
        }
        .appSecondaryActionButtonStyle()
      }
    }
  }
}
