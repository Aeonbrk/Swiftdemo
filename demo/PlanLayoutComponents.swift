import SwiftUI

enum AppPanelCardSurface {
  case glass
  case outlined
}

struct AppRouteScaffold<Content: View>: View {
  @ViewBuilder private let content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  var body: some View {
    scaffoldContent
      .padding(UIStyle.routeOuterPadding)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  @ViewBuilder
  private var scaffoldContent: some View {
    if #available(iOS 26, macOS 26, *) {
      GlassEffectContainer(spacing: UIStyle.panelGap) {
        baseScaffoldContent
      }
    } else {
      baseScaffoldContent
    }
  }

  private var baseScaffoldContent: some View {
    VStack(alignment: .leading, spacing: UIStyle.panelGap) {
      content()
    }
  }
}

struct AppPanelCard<Content: View>: View {
  private let innerPadding: CGFloat
  private let surface: AppPanelCardSurface
  @ViewBuilder private let content: () -> Content

  init(
    surface: AppPanelCardSurface = .glass,
    innerPadding: CGFloat = UIStyle.routeInnerPadding,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.surface = surface
    self.innerPadding = innerPadding
    self.content = content
  }

  var body: some View {
    let card = VStack(alignment: .leading, spacing: UIStyle.sectionSpacing) {
      self.content()
    }
    .padding(innerPadding)
    .frame(maxWidth: .infinity, alignment: .leading)

    switch surface {
    case .glass:
      card.appSurface(.panel, level: .regular, borderTone: .regular)
    case .outlined:
      card.appSurface(.field, level: .subtle, borderTone: .strong)
    }
  }
}

struct AppPanelList<Rows: View>: View {
  @ViewBuilder private let rows: () -> Rows

  init(@ViewBuilder rows: @escaping () -> Rows) {
    self.rows = rows
  }

  var body: some View {
    List {
      rows()
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .appListContainerGlass()
  }
}

struct AppSplitWorkspace<Leading: View, Trailing: View>: View {
  private let leadingMinWidth: CGFloat
  @ViewBuilder private let leading: () -> Leading
  @ViewBuilder private let trailing: () -> Trailing

  init(
    leadingMinWidth: CGFloat = UIStyle.contentColumnMinWidth,
    @ViewBuilder leading: @escaping () -> Leading,
    @ViewBuilder trailing: @escaping () -> Trailing
  ) {
    self.leadingMinWidth = leadingMinWidth
    self.leading = leading
    self.trailing = trailing
  }

  var body: some View {
    workspaceContent
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  @ViewBuilder
  private var workspaceContent: some View {
    if #available(iOS 26, macOS 26, *) {
      GlassEffectContainer(spacing: UIStyle.panelGap) {
        baseWorkspaceContent
      }
    } else {
      baseWorkspaceContent
    }
  }

  private var baseWorkspaceContent: some View {
    HStack(spacing: UIStyle.panelGap) {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        leading()
      }
      .padding(UIStyle.routeInnerPadding)
      .frame(minWidth: leadingMinWidth, maxHeight: .infinity, alignment: .topLeading)
      .appPanelGlass()

      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        trailing()
      }
      .padding(UIStyle.routeInnerPadding)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .appPanelGlass()
    }
  }
}
