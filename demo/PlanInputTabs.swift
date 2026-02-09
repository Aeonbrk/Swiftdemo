import Core
import SwiftUI

extension PlanInputView {
  enum ArtifactsSecondaryView: String, CaseIterable, Identifiable {
    case overview
    case cards
    case citations
    case history

    var id: String { rawValue }

    var title: String {
      switch self {
      case .overview:
        "概览"
      case .cards:
        "卡片"
      case .citations:
        "引用"
      case .history:
        "记录"
      }
    }

    var systemImage: String {
      switch self {
      case .overview:
        "square.grid.2x2"
      case .cards:
        "rectangle.stack"
      case .citations:
        "link"
      case .history:
        "clock.arrow.circlepath"
      }
    }
  }

  var inputMaterialView: some View {
    ScrollView {
      AppRouteScaffold {
        workflowProgressView

        AppPanelCard {
          VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
            Text("输入素材")
              .font(.headline)
            Text("把你的学习目标、背景和限制一次性写清楚，系统会据此生成结构化计划。")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        AppPanelCard {
          Text("计划标题")
            .font(.caption)
            .foregroundStyle(.secondary)

          TextField("例如：30 天掌握 Swift 并完成项目", text: $document.title)
            .textFieldStyle(.plain)
            .appFieldSurface()
            .font(.title3)
        }

        AppPanelCard {
          Text("原始输入")
            .font(.caption)
            .foregroundStyle(.secondary)

          TextEditor(text: $document.rawInput)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .appFieldSurface(.field)
            .frame(minHeight: 360)
        }
      }
    }
  }

  var generatePlanView: some View {
    ScrollView {
      AppRouteScaffold {
        workflowProgressView

        AppPanelCard {
          VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
            Text("生成计划")
              .font(.headline)
            Text("先生成结构化计划，再生成任务与卡片。高级参数默认折叠，不影响主流程。")
              .font(.caption)
              .foregroundStyle(.secondary)

            providerHintRow

            HStack(spacing: UIStyle.compactSpacing) {
              Button {
                generateStep1()
              } label: {
                Label("生成计划", systemImage: "sparkles")
              }
              .appPrimaryActionButtonStyle()
              .disabled(
                isGenerating || document.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              )

              Button {
                generateStep2()
              } label: {
                Label("生成任务", systemImage: "wand.and.stars")
              }
              .appSecondaryActionButtonStyle()
              .disabled(isGenerating || document.outline == nil)

              if isGenerating {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
        }

        DisclosureGroup("高级设置") {
          VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
            Picker("任务写入方式", selection: $step2MergeMode) {
              Text("覆盖（替换旧任务）").tag(Step2MergeMode.replace)
              Text("合并（保留旧任务）").tag(Step2MergeMode.merge)
            }
            .pickerStyle(.segmented)
            .disabled(isGenerating)
          }
          .padding(.top, UIStyle.compactSpacing)
        }
        .padding(.horizontal, UIStyle.routeInnerPadding)

        #if os(macOS)
          if activeProviderName == nil {
            Button {
              withAnimation(.snappy(duration: 0.2)) {
                isProviderInspectorVisible = true
              }
            } label: {
              Label("打开 Provider 设置", systemImage: "slider.horizontal.3")
            }
            .padding(.horizontal, UIStyle.routeInnerPadding)
            .appSecondaryActionButtonStyle()
          }
        #endif

        if let outline = document.outline, !outline.planMarkdown.isEmpty {
          AppPanelCard {
            VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
              Text("计划预览")
                .font(.headline)
              previewText(for: outline.planMarkdown)
            }
          }
        } else {
          AppPanelCard {
            AppEmptyStatePanel(
              title: "尚未生成计划",
              systemImage: "doc.text.magnifyingglass",
              description: "请先点击“生成计划”。"
            )
          }
        }
      }
    }
  }

  var organizeArtifactsView: some View {
    AppRouteScaffold {
      workflowProgressView

      AppPanelCard {
        VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
          Text("整理产物")
            .font(.headline)
          Text("默认展示任务与卡片总览，详细内容在“更多”里按需查看。")
            .font(.caption)
            .foregroundStyle(.secondary)

          HStack(spacing: UIStyle.compactSpacing) {
            AppExportMenuButton(
              title: "导出任务",
              items: [
                AppExportMenuItem(
                  id: "todos-csv",
                  title: "导出 CSV（兼容）",
                  systemImage: "tablecells.fill"
                ) {
                  exportTodosCSV()
                },
                AppExportMenuItem(
                  id: "todos-csv-extended",
                  title: "导出 CSV（扩展）",
                  systemImage: "tablecells.badge.ellipsis"
                ) {
                  exportTodosExtendedCSV()
                }
              ]
            )
            .disabled(document.todos.isEmpty)

            AppExportMenuButton(
              title: "导出卡片",
              items: [
                AppExportMenuItem(
                  id: "cards-tsv",
                  title: "导出 TSV",
                  systemImage: "tablecells"
                ) {
                  exportFlashcardsTSV()
                },
                AppExportMenuItem(
                  id: "cards-csv",
                  title: "导出 CSV",
                  systemImage: "tablecells.fill"
                ) {
                  exportFlashcardsCSV()
                }
              ]
            )
            .disabled(document.flashcards.isEmpty)

            Spacer(minLength: UIStyle.compactSpacing)

            Menu {
              ForEach(ArtifactsSecondaryView.allCases, id: \.self) { view in
                Button {
                  selectedArtifactsSecondaryView = view
                } label: {
                  Label(view.title, systemImage: view.systemImage)
                }
              }
            } label: {
              Label("更多", systemImage: "ellipsis.circle")
            }
            .appSecondaryActionButtonStyle()
          }
        }
      }

      switch selectedArtifactsSecondaryView {
      case .overview:
        artifactsOverviewPanel
      case .cards:
        cardsSection
      case .citations:
        citationsSection
      case .history:
        historySection
      }
    }
  }

  var cardsSection: some View {
    AppSplitWorkspace(leadingMinWidth: UIStyle.contentColumnMinWidth) {
      cardsToolbar
      cardsList
    } trailing: {
      cardsDetail
    }
  }

  var citationsSection: some View {
    AppPanelList {
      ForEach(sortedCitations, id: \.id) { citation in
        citationRow(citation)
          .padding(.horizontal, UIStyle.panelInnerPadding)
          .padding(.vertical, UIStyle.listRowVerticalPadding)
          .appRowGlass()
          .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
  }

  var historySection: some View {
    AppPanelList {
      ForEach(sortedGenerations, id: \.id) { record in
        generationRow(record)
          .padding(.horizontal, UIStyle.panelInnerPadding)
          .padding(.vertical, UIStyle.listRowVerticalPadding)
          .appRowGlass()
          .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
    }
  }

  var artifactsOverviewPanel: some View {
    AppPanelCard {
      VStack(alignment: .leading, spacing: UIStyle.compactSpacing) {
        Text("产物概览")
          .font(.headline)

        HStack(spacing: UIStyle.compactSpacing) {
          Label("任务 \(document.todos.count)", systemImage: "checklist")
          Label("卡片 \(document.flashcards.count)", systemImage: "rectangle.stack")
          Label("引用 \(document.citations.count)", systemImage: "link")
          Label("记录 \(document.generations.count)", systemImage: "clock.arrow.circlepath")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }

}
