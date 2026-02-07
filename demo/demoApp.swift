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
  private let modelContainer: ModelContainer

  init() {
    do {
      self.modelContainer = try CoreModelContainer.make(inMemory: false)
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
