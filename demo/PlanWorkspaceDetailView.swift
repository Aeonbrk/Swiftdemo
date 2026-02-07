import SwiftUI

struct PlanWorkspaceDetailView: View {
  let selectedRoute: PlanWorkspaceRoute

  let inputView: AnyView
  let previewView: AnyView
  let cardsView: AnyView
  let todosView: AnyView
  let citationsView: AnyView
  let historyView: AnyView

  var body: some View {
    Group {
      switch selectedRoute {
      case .input:
        inputView
      case .preview:
        previewView
      case .cards:
        cardsView
      case .todos:
        todosView
      case .citations:
        citationsView
      case .history:
        historyView
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
