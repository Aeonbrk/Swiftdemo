import SwiftUI

extension View {
  @available(iOS 26, macOS 26, *)
  private var appMediumTopBarGlass: Glass {
    Glass.regular.tint(.white.opacity(0.16)).interactive()
  }

  @available(iOS 26, macOS 26, *)
  private var appMediumPanelGlass: Glass {
    Glass.regular.tint(.white.opacity(0.12))
  }

  @available(iOS 26, macOS 26, *)
  private func appMediumChipGlass(interactive: Bool) -> Glass {
    let glass = Glass.regular.tint(.white.opacity(0.14))
    return interactive ? glass.interactive() : glass
  }

  @ViewBuilder
  func appTopBarGlass() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.glassEffect(appMediumTopBarGlass, in: .rect(cornerRadius: UIStyle.cornerRadius))
    } else {
      self.background(
        .ultraThinMaterial,
        in: RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
      )
    }
  }

  @ViewBuilder
  func appPanelGlass() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.glassEffect(appMediumPanelGlass, in: .rect(cornerRadius: UIStyle.cornerRadius))
    } else {
      self.background(
        .thinMaterial,
        in: RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
      )
    }
  }

  @ViewBuilder
  func appChipGlass(interactive: Bool = false) -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.glassEffect(appMediumChipGlass(interactive: interactive), in: .rect(cornerRadius: UIStyle.cornerRadius))
    } else {
      self.background(
        .thinMaterial,
        in: RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
      )
    }
  }

  func appInputSurface() -> some View {
    self
      .padding(.horizontal, UIStyle.panelInnerPadding)
      .padding(.vertical, 8)
      .background {
        RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
          .fill(Color.secondary.opacity(0.12))
      }
      .overlay {
        RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
          .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
      }
  }

  @ViewBuilder
  func appPrimaryActionButtonStyle() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: UIStyle.cornerRadius))
    } else {
      self.buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: UIStyle.cornerRadius))
    }
  }

  @ViewBuilder
  func appSecondaryActionButtonStyle() -> some View {
    if #available(iOS 26, macOS 26, *) {
      self.buttonStyle(.glass)
        .buttonBorderShape(.roundedRectangle(radius: UIStyle.cornerRadius))
    } else {
      self.buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: UIStyle.cornerRadius))
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
