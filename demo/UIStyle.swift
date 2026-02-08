import SwiftUI

enum UIStyle {
  enum SurfaceTone {
    case shell
    case panel
    case row
    case field
  }

  enum GlassLevel {
    case subtle
    case regular
    case strong
  }

  enum BorderTone {
    case subtle
    case regular
    case strong
    case focus
  }

  static let cornerRadius: CGFloat = 12

  static let workspacePadding: CGFloat = 12
  static let panelPadding: CGFloat = 12
  static let panelInnerPadding: CGFloat = 10
  static let routeOuterPadding: CGFloat = panelPadding
  static let routeInnerPadding: CGFloat = panelInnerPadding
  static let panelGap: CGFloat = 10
  static let panelCornerRadius: CGFloat = cornerRadius
  static let chipCornerRadius: CGFloat = cornerRadius
  static let rowCornerRadius: CGFloat = cornerRadius
  static let panelBorderOpacity: CGFloat = 0.14
  static let focusRingOpacity: CGFloat = 0.95

  static let sectionSpacing: CGFloat = 12
  static let compactSpacing: CGFloat = 8

  static let toolbarHorizontalPadding: CGFloat = 12
  static let toolbarVerticalPadding: CGFloat = 10

  static let workspaceColumnSpacing: CGFloat = 10
  static let workspaceSidebarMinWidth: CGFloat = 156
  static let workspaceSidebarIdealWidth: CGFloat = 172
  static let providerInspectorMinWidth: CGFloat = 360
  static let providerInspectorWidth: CGFloat = 420
  static let providerInspectorMaxWidth: CGFloat = 520
  static let contentColumnMinWidth: CGFloat = 320

  static let sidebarRowMinHeight: CGFloat = 38
  static let listRowVerticalPadding: CGFloat = 6
  static let floatingAddButtonSize: CGFloat = 32
  static let floatingAddButtonBottomPadding: CGFloat = 14

  static let positiveStatusColor: Color = .green
  static let warningStatusColor: Color = .orange
  static let destructiveStatusColor: Color = .red

  static let selectedRowOpacity: CGFloat = 0.12

  static func tintOpacity(for tone: SurfaceTone, level: GlassLevel) -> CGFloat {
    switch tone {
    case .shell:
      return shellTintOpacity(for: level)
    case .panel:
      return panelTintOpacity(for: level)
    case .row:
      return rowTintOpacity(for: level)
    case .field:
      return fieldTintOpacity(for: level)
    }
  }

  static func fillOpacity(for tone: SurfaceTone) -> CGFloat {
    switch tone {
    case .shell: 0.16
    case .panel: 0.11
    case .row: 0.07
    case .field: 0.10
    }
  }

  static func borderOpacity(for tone: BorderTone) -> CGFloat {
    switch tone {
    case .subtle: 0.12
    case .regular: 0.18
    case .strong: 0.24
    case .focus: 0.95
    }
  }

  private static func shellTintOpacity(for level: GlassLevel) -> CGFloat {
    switch level {
    case .subtle: 0.08
    case .regular: 0.10
    case .strong: 0.12
    }
  }

  private static func panelTintOpacity(for level: GlassLevel) -> CGFloat {
    switch level {
    case .subtle: 0.06
    case .regular: 0.08
    case .strong: 0.11
    }
  }

  private static func rowTintOpacity(for level: GlassLevel) -> CGFloat {
    switch level {
    case .subtle: 0.05
    case .regular: 0.07
    case .strong: 0.09
    }
  }

  private static func fieldTintOpacity(for level: GlassLevel) -> CGFloat {
    switch level {
    case .subtle: 0.04
    case .regular: 0.05
    case .strong: 0.08
    }
  }
}
