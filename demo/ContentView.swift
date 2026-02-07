//
//  ContentView.swift
//  demo
//
//  Created by oian on 2026/1/8.
//

import Core
import SwiftData
import SwiftUI
#if canImport(AppKit)
  import AppKit
#endif

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \PlanDocument.updatedAt, order: .reverse) private var documents: [PlanDocument]

  @State private var selectedDocumentID: UUID?
  @State private var searchText: String = ""

  private var filteredDocuments: [PlanDocument] {
    let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard keyword.isEmpty == false else { return documents }
    return documents.filter { document in
      document.title.localizedCaseInsensitiveContains(keyword)
    }
  }

  private var selectedDocument: PlanDocument? {
    guard let selectedDocumentID else { return nil }
    return documents.first(where: { $0.id == selectedDocumentID })
  }

  var body: some View {
    NavigationSplitView {
      Group {
        if filteredDocuments.isEmpty {
          ContentUnavailableView(
            searchText.isEmpty ? "还没有学习计划" : "没有匹配结果",
            systemImage: searchText.isEmpty ? "doc.badge.plus" : "magnifyingglass"
          )
          .padding(UIStyle.panelPadding)
        } else {
          List(selection: $selectedDocumentID) {
            ForEach(filteredDocuments, id: \.id) { document in
              Text(document.title)
                .tag(document.id)
                .contextMenu {
                  Button(role: .destructive) {
                    deleteDocument(document)
                  } label: {
                    Label("删除", systemImage: "trash")
                  }
                }
            }
            .onDelete(perform: deleteFilteredDocuments)
          }
        }
      }
      .searchable(text: $searchText, prompt: "搜索计划标题")
      .navigationTitle("学习计划")
      .toolbar {
        #if os(macOS)
          ToolbarItem(placement: .navigation) {
            Button {
              toggleSidebar()
            } label: {
              Image(systemName: "sidebar.left")
            }
            .appSecondaryActionButtonStyle()
            .help("展开或收起文档侧栏")
          }
        #endif

        ToolbarItem(placement: .primaryAction) {
          Button(action: createDocument) {
            Label("新建计划", systemImage: "plus")
          }
          .appPrimaryActionButtonStyle()
        }
      }
    } detail: {
      if let document = selectedDocument {
        PlanInputView(document: document)
      } else {
        ContentUnavailableView("请选择一个计划", systemImage: "doc.text")
      }
    }
    .onAppear {
      if selectedDocumentID == nil {
        selectedDocumentID = documents.first?.id
      }
    }
  }

  private func createDocument() {
    let document = PlanDocument(title: "新计划", rawInput: "")
    modelContext.insert(document)
    selectedDocumentID = document.id
  }

  private func deleteFilteredDocuments(at offsets: IndexSet) {
    for index in offsets {
      deleteDocument(filteredDocuments[index])
    }
  }

  private func deleteDocument(_ document: PlanDocument) {
    modelContext.delete(document)

    if let selectedDocumentID,
      documents.contains(where: { $0.id == selectedDocumentID }) == false {
      self.selectedDocumentID = documents.first?.id
    }
  }

  #if os(macOS)
    private func toggleSidebar() {
      NSApp.keyWindow?.firstResponder?.tryToPerform(
        #selector(NSSplitViewController.toggleSidebar(_:)),
        with: nil
      )
    }
  #endif
}

#Preview {
  ContentView()
}
