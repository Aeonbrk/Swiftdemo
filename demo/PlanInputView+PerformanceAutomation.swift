#if os(macOS)
  import Core
  import SwiftUI

  extension PlanInputView {
    static let isPerformanceAutomationEnabled =
      ProcessInfo.processInfo.environment["DEMO_PERF_AUTOMATION"] == "1"
    static let useLegacyRouteSwitchRendering =
      ProcessInfo.processInfo.environment["DEMO_PERF_USE_LEGACY_ROUTE_SWITCH"] == "1"
    static let automationRouteSwitchIntervalNanoseconds: UInt64 = 200_000_000
    func setupRouteAutomationIfNeeded() {
      guard Self.isPerformanceAutomationEnabled else { return }
      if routeAutomationTask == nil {
        routeAutomationTask = Task { @MainActor in
          await runRouteAutomationLoop()
        }
      }
    }

    @MainActor
    func runRouteAutomationLoop() async {
      let routes = PlanWorkspaceRoute.allCases
      guard routes.isEmpty == false else { return }

      while Task.isCancelled == false {
        for route in routes {
          if Task.isCancelled {
            return
          }

          selectedRoute = route
          do {
            try await Task.sleep(nanoseconds: Self.automationRouteSwitchIntervalNanoseconds)
          } catch {
            return
          }
        }
      }
    }
  }
#endif
