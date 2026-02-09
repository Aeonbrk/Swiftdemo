import SwiftUI

struct PlanWorkspaceDetailView<
  InputMaterialView: View,
  GeneratePlanView: View,
  ArtifactsView: View,
  ExecutionView: View
>: View {
  let selectedRoute: PlanWorkspaceRoute
  let useLegacyRouteSwitchRendering: Bool

  private let inputMaterialView: () -> InputMaterialView
  private let generatePlanView: () -> GeneratePlanView
  private let organizeArtifactsView: () -> ArtifactsView
  private let todayExecutionView: () -> ExecutionView

  init(
    selectedRoute: PlanWorkspaceRoute,
    useLegacyRouteSwitchRendering: Bool = false,
    @ViewBuilder inputMaterialView: @escaping () -> InputMaterialView,
    @ViewBuilder generatePlanView: @escaping () -> GeneratePlanView,
    @ViewBuilder organizeArtifactsView: @escaping () -> ArtifactsView,
    @ViewBuilder todayExecutionView: @escaping () -> ExecutionView
  ) {
    self.selectedRoute = selectedRoute
    self.useLegacyRouteSwitchRendering = useLegacyRouteSwitchRendering
    self.inputMaterialView = inputMaterialView
    self.generatePlanView = generatePlanView
    self.organizeArtifactsView = organizeArtifactsView
    self.todayExecutionView = todayExecutionView
  }

  var body: some View {
    Group {
      switch selectedRoute {
      case .inputMaterial:
        inputMaterialView()
      case .generatePlan:
        generatePlanView()
      case .organizeArtifacts:
        organizeArtifactsView()
      case .todayExecution:
        todayExecutionView()
      }
    }
    .id(useLegacyRouteSwitchRendering ? selectedRoute : nil)
    .animation(
      useLegacyRouteSwitchRendering ? .snappy(duration: 0.2) : nil,
      value: selectedRoute
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
