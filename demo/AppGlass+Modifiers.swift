import SwiftUI

extension View {
  @ViewBuilder
  func appTopBarGlass() -> some View {
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
  func appPanelGlass() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.glassEffect(.regular, in: .rect(cornerRadius: UIStyle.panelCornerRadius))
    } else {
      self.background(
        .thinMaterial,
        in: RoundedRectangle(cornerRadius: UIStyle.panelCornerRadius, style: .continuous)
      )
    }
  }

  @ViewBuilder
  func appChipGlass(interactive: Bool = false) -> some View {
    if #available(iOS 26, macOS 26, *) {
      let glass = interactive ? Glass.regular.interactive() : Glass.regular
      self.glassEffect(glass, in: .rect(cornerRadius: UIStyle.chipCornerRadius))
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

  @ViewBuilder
  func appToolbarSurface() -> some View {
    self.appTopBarGlass()
  }

  @ViewBuilder
  func appPanelSurface() -> some View {
    self.appPanelGlass()
  }

  @ViewBuilder
  func appStatusChipSurface() -> some View {
    self.appChipGlass()
  }
}
