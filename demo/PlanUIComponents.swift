import SwiftUI

struct AppActionBar<Content: View>: View {
  @ViewBuilder private let content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  var body: some View {
    if #available(iOS 26, macOS 26, *) {
      GlassEffectContainer(spacing: UIStyle.compactSpacing) {
        contentView
      }
    } else {
      contentView
    }
  }

  private var contentView: some View {
    content()
      .padding(.horizontal, UIStyle.toolbarHorizontalPadding)
      .padding(.vertical, UIStyle.toolbarVerticalPadding)
      .appTopBarGlass()
  }
}

struct AppEmptyStatePanel: View {
  let title: String
  let systemImage: String
  let description: String?

  init(title: String, systemImage: String, description: String? = nil) {
    self.title = title
    self.systemImage = systemImage
    self.description = description
  }

  var body: some View {
    ContentUnavailableView {
      Label(title, systemImage: systemImage)
    } description: {
      if let description, !description.isEmpty {
        Text(description)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct AppExportMenuItem: Identifiable {
  let id: String
  let title: String
  let systemImage: String
  let action: () -> Void
}

struct AppExportMenuButton: View {
  let title: String
  let items: [AppExportMenuItem]

  var body: some View {
    Menu {
      ForEach(items) { item in
        Button {
          item.action()
        } label: {
          Label(item.title, systemImage: item.systemImage)
        }
      }
    } label: {
      Label(title, systemImage: "square.and.arrow.up")
    }
    .appSecondaryActionButtonStyle()
  }
}
