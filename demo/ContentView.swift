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
  @State private var searchText: String = ""
  @State private var isCreateButtonHovered = false
  @FocusState private var focusedDocumentID: UUID?
  @FocusState private var isCreateButtonFocused: Bool

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
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        Group {
          if filteredDocuments.isEmpty {
            ContentUnavailableView(
              searchText.isEmpty ? "还没有学习计划" : "没有匹配结果",
              systemImage: searchText.isEmpty ? "doc.badge.plus" : "magnifyingglass"
            )
            .padding(UIStyle.panelPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .appPanelGlass()
          } else {
            List {
              ForEach(filteredDocuments, id: \.id) { document in
                documentRow(document)
                  .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
                  .listRowSeparator(.hidden)
                  .listRowBackground(Color.clear)
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
          }
        }

        HStack {
          Spacer()
          Button(action: createDocument) {
            Image(systemName: "plus")
              .font(.headline.weight(.semibold))
              .frame(width: UIStyle.floatingAddButtonSize, height: UIStyle.floatingAddButtonSize)
          }
          .focused($isCreateButtonFocused)
          .buttonStyle(.plain)
          .appChipGlass(interactive: true)
          .appFocusRing(isFocused: isCreateButtonFocused)
          .scaleEffect(isCreateButtonHovered ? 1.05 : 1.0)
          .animation(.easeOut(duration: 0.18), value: isCreateButtonHovered)
          .help("新建计划")
          .accessibilityLabel("新建计划")
          #if os(macOS)
            .onHover { isHovering in
              isCreateButtonHovered = isHovering
            }
          #endif
          Spacer()
        }
        .padding(.bottom, UIStyle.floatingAddButtonBottomPadding)
      }
      .padding(.horizontal, UIStyle.panelInnerPadding)
      .padding(.top, UIStyle.panelInnerPadding)
      .padding(.bottom, UIStyle.compactSpacing)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .searchable(text: $searchText, prompt: "搜索计划标题")
      .navigationTitle("学习计划")
      .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 240)
      .appSidebarSurface()
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

  private func documentRow(_ document: PlanDocument) -> some View {
    let isSelected = selectedDocumentID == document.id

    return Button {
      selectedDocumentID = document.id
    } label: {
      HStack(spacing: UIStyle.compactSpacing) {
        Text(document.title)
          .lineLimit(1)
        Spacer(minLength: UIStyle.compactSpacing)
      }
      .padding(.horizontal, UIStyle.panelInnerPadding)
      .padding(.vertical, UIStyle.listRowVerticalPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: UIStyle.rowCornerRadius, style: .continuous)
          .fill(isSelected ? Color.accentColor.opacity(UIStyle.selectedRowOpacity) : Color.clear)
      }
      .appRowGlass(interactive: true)
      .appFocusRing(isFocused: focusedDocumentID == document.id)
    }
    .focused($focusedDocumentID, equals: document.id)
    .buttonStyle(.plain)
    .contentShape(Rectangle())
  }

}

#Preview {
  ContentView()
}
