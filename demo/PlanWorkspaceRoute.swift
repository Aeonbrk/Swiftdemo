import SwiftUI

enum PlanWorkspaceSection: String, CaseIterable, Identifiable {
  case inputAndGeneration
  case learningArtifacts
  case evidenceAndHistory

  var id: String { rawValue }

  var title: String {
    switch self {
    case .inputAndGeneration:
      "输入与生成"
    case .learningArtifacts:
      "学习产物"
    case .evidenceAndHistory:
      "证据与历史"
    }
  }

  var routes: [PlanWorkspaceRoute] {
    switch self {
    case .inputAndGeneration:
      [.input, .preview]
    case .learningArtifacts:
      [.cards, .todos, .execution]
    case .evidenceAndHistory:
      [.citations, .history]
    }
  }
}

enum PlanWorkspaceRoute: String, CaseIterable, Identifiable, Hashable {
  case input
  case preview
  case cards
  case todos
  case execution
  case citations
  case history

  var id: String { rawValue }

  var title: String {
    switch self {
    case .input:
      "输入"
    case .preview:
      "预览"
    case .cards:
      "卡片"
    case .todos:
      "任务"
    case .execution:
      "执行"
    case .citations:
      "引用"
    case .history:
      "记录"
    }
  }

  var systemImage: String {
    switch self {
    case .input:
      "square.and.pencil"
    case .preview:
      "doc.text.magnifyingglass"
    case .cards:
      "rectangle.stack"
    case .todos:
      "checklist"
    case .execution:
      "bolt.horizontal.circle"
    case .citations:
      "link"
    case .history:
      "clock.arrow.circlepath"
    }
  }

  var section: PlanWorkspaceSection {
    switch self {
    case .input, .preview:
      .inputAndGeneration
    case .cards, .todos, .execution:
      .learningArtifacts
    case .citations, .history:
      .evidenceAndHistory
    }
  }

  var keyboardShortcutKey: KeyEquivalent {
    switch self {
    case .input:
      "1"
    case .preview:
      "2"
    case .cards:
      "3"
    case .todos:
      "4"
    case .execution:
      "5"
    case .citations:
      "6"
    case .history:
      "7"
    }
  }

  var shortcutDisplay: String {
    switch self {
    case .input:
      "1"
    case .preview:
      "2"
    case .cards:
      "3"
    case .todos:
      "4"
    case .execution:
      "5"
    case .citations:
      "6"
    case .history:
      "7"
    }
  }
}
