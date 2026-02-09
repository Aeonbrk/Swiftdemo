import SwiftUI

enum PlanWorkspaceRoute: String, CaseIterable, Identifiable, Hashable {
  case inputMaterial
  case generatePlan
  case organizeArtifacts
  case todayExecution

  var id: String { rawValue }

  var title: String {
    switch self {
    case .inputMaterial:
      "输入素材"
    case .generatePlan:
      "生成计划"
    case .organizeArtifacts:
      "整理产物"
    case .todayExecution:
      "今日执行"
    }
  }

  var systemImage: String {
    switch self {
    case .inputMaterial:
      "square.and.pencil"
    case .generatePlan:
      "doc.text.magnifyingglass"
    case .organizeArtifacts:
      "rectangle.stack"
    case .todayExecution:
      "bolt.horizontal.circle"
    }
  }

  var keyboardShortcutKey: KeyEquivalent {
    switch self {
    case .inputMaterial:
      "1"
    case .generatePlan:
      "2"
    case .organizeArtifacts:
      "3"
    case .todayExecution:
      "4"
    }
  }

  var shortcutDisplay: String {
    switch self {
    case .inputMaterial:
      "1"
    case .generatePlan:
      "2"
    case .organizeArtifacts:
      "3"
    case .todayExecution:
      "4"
    }
  }
}
