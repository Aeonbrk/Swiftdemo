import SwiftUI

enum UIStyle {
  static let panelPadding: CGFloat = 12
  static let panelCornerRadius: CGFloat = 14
  static let chipCornerRadius: CGFloat = 12
}

extension View {
  @ViewBuilder
  func appPanelSurface() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: UIStyle.panelCornerRadius))
    } else {
      self.background(
        .ultraThinMaterial,
        in: RoundedRectangle(cornerRadius: UIStyle.panelCornerRadius, style: .continuous)
      )
    }
  }

  @ViewBuilder
  func appStatusChipSurface() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.glassEffect(.regular, in: .rect(cornerRadius: UIStyle.chipCornerRadius))
    } else {
      self.background(
        .thinMaterial,
        in: RoundedRectangle(cornerRadius: UIStyle.chipCornerRadius, style: .continuous)
      )
    }
  }

  @ViewBuilder
  func appPrimaryActionButtonStyle() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.buttonStyle(.glassProminent)
    } else {
      self.buttonStyle(.borderedProminent)
    }
  }

  @ViewBuilder
  func appSecondaryActionButtonStyle() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.buttonStyle(.glass)
    } else {
      self.buttonStyle(.bordered)
    }
  }
}
