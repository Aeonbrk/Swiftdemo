import SwiftUI

struct PlanWorkspaceSidebarView: View {
  @Binding var selectedRoute: PlanWorkspaceRoute

  var body: some View {
    List {
      ForEach(PlanWorkspaceSection.allCases) { section in
        Section(section.title) {
          ForEach(section.routes) { route in
            routeButton(route)
              .listRowInsets(
                EdgeInsets(
                  top: 4,
                  leading: UIStyle.panelInnerPadding,
                  bottom: 4,
                  trailing: UIStyle.panelInnerPadding
                )
              )
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
          }
        }
      }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .padding(.vertical, 4)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .appPanelGlass()
    .accessibilityIdentifier("plan_workspace_sidebar")
  }

  private func routeButton(_ route: PlanWorkspaceRoute) -> some View {
    Button {
      selectedRoute = route
    } label: {
      HStack(spacing: UIStyle.compactSpacing) {
        Image(systemName: route.systemImage)
          .frame(width: 18)

        Text(route.title)
          .lineLimit(1)

        Spacer(minLength: UIStyle.compactSpacing)

        Text("⌘\(route.shortcutDisplay)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .font(.callout)
      .padding(.horizontal, UIStyle.panelInnerPadding)
      .padding(.vertical, 8)
      .frame(minHeight: UIStyle.sidebarRowMinHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: UIStyle.rowCornerRadius, style: .continuous)
          .fill(selectedRoute == route ? Color.accentColor.opacity(UIStyle.selectedRowOpacity) : Color.clear)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .keyboardShortcut(route.keyboardShortcutKey, modifiers: .command)
  }
}
