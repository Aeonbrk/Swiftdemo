//
//  demoApp.swift
//  demo
//
//  Created by oian on 2026/1/8.
//

import Core
import SwiftData
import SwiftUI

@main
struct DemoApp: App {
  private static let isPerformanceAutomationEnabled =
    ProcessInfo.processInfo.environment["DEMO_PERF_AUTOMATION"] == "1"

  private let modelContainer: ModelContainer

  init() {
    do {
      self.modelContainer = try CoreModelContainer.make(
        inMemory: Self.isPerformanceAutomationEnabled
      )
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(modelContainer)
  }
}
