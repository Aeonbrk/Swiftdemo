import SwiftUI

struct PlanWorkspaceDetailView<
  InputView: View,
  PreviewView: View,
  CardsView: View,
  TodosView: View,
  ExecutionView: View,
  CitationsView: View,
  HistoryView: View
>: View {
  let selectedRoute: PlanWorkspaceRoute

  private let inputView: () -> InputView
  private let previewView: () -> PreviewView
  private let cardsView: () -> CardsView
  private let todosView: () -> TodosView
  private let executionView: () -> ExecutionView
  private let citationsView: () -> CitationsView
  private let historyView: () -> HistoryView

  init(
    selectedRoute: PlanWorkspaceRoute,
    @ViewBuilder inputView: @escaping () -> InputView,
    @ViewBuilder previewView: @escaping () -> PreviewView,
    @ViewBuilder cardsView: @escaping () -> CardsView,
    @ViewBuilder todosView: @escaping () -> TodosView,
    @ViewBuilder executionView: @escaping () -> ExecutionView,
    @ViewBuilder citationsView: @escaping () -> CitationsView,
    @ViewBuilder historyView: @escaping () -> HistoryView
  ) {
    self.selectedRoute = selectedRoute
    self.inputView = inputView
    self.previewView = previewView
    self.cardsView = cardsView
    self.todosView = todosView
    self.executionView = executionView
    self.citationsView = citationsView
    self.historyView = historyView
  }

  var body: some View {
    Group {
      switch selectedRoute {
      case .input:
        inputView()
      case .preview:
        previewView()
      case .cards:
        cardsView()
      case .todos:
        todosView()
      case .execution:
        executionView()
      case .citations:
        citationsView()
      case .history:
        historyView()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
