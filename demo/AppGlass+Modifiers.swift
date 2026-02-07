import SwiftUI

extension View {
  @available(iOS 26, macOS 26, *)
  private func appGlass(
    tone: UIStyle.SurfaceTone,
    level: UIStyle.GlassLevel,
    interactive: Bool
  ) -> Glass {
    let base = Glass.regular.tint(.white.opacity(UIStyle.tintOpacity(for: tone, level: level)))
    return interactive ? base.interactive() : base
  }

  private func appBorderColor(_ tone: UIStyle.BorderTone) -> Color {
    Color.white.opacity(UIStyle.borderOpacity(for: tone))
  }

  @ViewBuilder
  func appSurface(
    _ tone: UIStyle.SurfaceTone,
    level: UIStyle.GlassLevel = .regular,
    interactive: Bool = false,
    borderTone: UIStyle.BorderTone = .regular
  ) -> some View {
    if #available(iOS 26, macOS 26, *) {
      self
        .glassEffect(
          appGlass(tone: tone, level: level, interactive: interactive),
          in: .rect(cornerRadius: UIStyle.cornerRadius)
        )
        .overlay {
          RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
            .stroke(appBorderColor(borderTone), lineWidth: 1)
        }
    } else {
      self
        .background(
          tone == .field ? .regularMaterial : .ultraThinMaterial,
          in: RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
            .stroke(appBorderColor(borderTone), lineWidth: 1)
        }
    }
  }

  func appFieldSurface(_ tone: UIStyle.SurfaceTone = .field) -> some View {
    self
      .padding(.horizontal, UIStyle.panelInnerPadding)
      .padding(.vertical, 8)
      .background {
        RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
          .fill(Color.black.opacity(UIStyle.fillOpacity(for: tone)))
      }
      .appSurface(.field, level: .subtle, borderTone: .strong)
  }

  @ViewBuilder
  func appListSurface() -> some View {
    self.appSurface(.panel, level: .regular, borderTone: .regular)
  }

  @ViewBuilder
  func appSidebarSurface() -> some View {
    self.appSurface(.shell, level: .regular, borderTone: .regular)
  }

  @ViewBuilder
  func appFocusRing(isFocused: Bool) -> some View {
    self.overlay {
      RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
        .stroke(
          Color.accentColor.opacity(isFocused ? UIStyle.focusRingOpacity : 0),
          lineWidth: isFocused ? 1.5 : 0
        )
    }
  }

  @ViewBuilder
  func appTopBarGlass() -> some View {
    self.appSurface(.shell, level: .strong, interactive: true, borderTone: .strong)
  }

  @ViewBuilder
  func appPanelGlass() -> some View {
    self.appSurface(.panel, level: .regular, borderTone: .regular)
  }

  @ViewBuilder
  func appChipGlass(interactive: Bool = false) -> some View {
    self.appSurface(.row, level: .strong, interactive: interactive, borderTone: .strong)
  }

  func appInputSurface(transparent: Bool = true) -> some View {
    let tone: UIStyle.SurfaceTone = transparent ? .row : .field
    return self
      .padding(.horizontal, UIStyle.panelInnerPadding)
      .padding(.vertical, 8)
      .background {
        RoundedRectangle(cornerRadius: UIStyle.cornerRadius, style: .continuous)
          .fill(Color.black.opacity(UIStyle.fillOpacity(for: tone)))
      }
      .appSurface(.field, level: .subtle, borderTone: .strong)
  }

  @ViewBuilder
  func appRowGlass(interactive: Bool = false) -> some View {
    self.appSurface(.row, level: .regular, interactive: interactive, borderTone: .regular)
  }

  @ViewBuilder
  func appListContainerGlass() -> some View {
    self.appListSurface()
  }

  @ViewBuilder
  func appEditorChromeGlass() -> some View {
    self.appSurface(.field, level: .subtle, borderTone: .strong)
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
