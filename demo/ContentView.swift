//
//  ContentView.swift
//  demo
//
//  Created by oian on 2026/1/8.
//

import Core
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \PlanDocument.updatedAt, order: .reverse) private var documents: [PlanDocument]

  @State private var selectedDocumentID: UUID?

  private var selectedDocument: PlanDocument? {
    guard let selectedDocumentID else { return nil }
    return documents.first(where: { $0.id == selectedDocumentID })
  }

  var body: some View {
    NavigationSplitView {
      List(selection: $selectedDocumentID) {
        ForEach(documents, id: \.id) { document in
          Text(document.title)
            .tag(document.id)
        }
        .onDelete(perform: deleteDocuments)
      }
      .navigationTitle("Plans")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: createDocument) {
            Label("New Plan", systemImage: "plus")
          }
        }
      }
    } detail: {
      if let document = selectedDocument {
        PlanInputView(document: document)
      } else {
        ContentUnavailableView("Select a plan", systemImage: "doc.text")
      }
    }
    .onAppear {
      if selectedDocumentID == nil {
        selectedDocumentID = documents.first?.id
      }
    }
  }

  private func createDocument() {
    let document = PlanDocument(title: "New Plan", rawInput: "")
    modelContext.insert(document)
    selectedDocumentID = document.id
  }

  private func deleteDocuments(at offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(documents[index])
    }

    if let selectedDocumentID,
      documents.contains(where: { $0.id == selectedDocumentID }) == false {
      self.selectedDocumentID = documents.first?.id
    }
  }
}

#Preview {
  ContentView()
}
