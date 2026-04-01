// NoteChain/Features/NotesList/NotesListView.swift
// ノート一覧画面 — 検索・ソート・セクション区切り・スワイプ削除

import SwiftData
import SwiftUI

/// ノート一覧のルートビュー。
/// NavigationStack の root として使用し、詳細画面への push 遷移を管理する。
struct NotesListView: View {

    @State private var viewModel: NotesListViewModel
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    init(modelContext: ModelContext) {
        _viewModel = State(wrappedValue: NotesListViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack(path: Bindable(router).notesPath) {
            Group {
                if viewModel.filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("tab_notes")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("search_notes_prompt")
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
                if viewModel.keywordFilter != nil || viewModel.languageFilter != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("clear_filters") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .noteDetail(let id):
                    NoteDetailView(noteID: id, modelContext: modelContext)
                case .keywordFilter(let keyword):
                    filteredView(for: keyword)
                default:
                    EmptyView()
                }
            }
        }
        .alert(
            "error_title",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("ok_button", role: .cancel) { viewModel.clearError() }
        } message: {
            if let msg = viewModel.errorMessage { Text(msg) }
        }
    }

    // MARK: - Subviews

    private var notesList: some View {
        List {
            // アクティブフィルターバナー
            if let kf = viewModel.keywordFilter {
                Section {
                    Label(
                        String(localized: "filtering_by_keyword \(kf)"),
                        systemImage: "tag.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                }
            }

            // 日付セクション
            ForEach(viewModel.sortedSectionDates, id: \.self) { date in
                Section(header: Text(date.sectionHeaderFormatted).font(.subheadline)) {
                    ForEach(viewModel.groupedNotes[date] ?? []) { note in
                        NoteRowView(note: note)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                router.push(.noteDetail(note.id), in: .notes)
                            }
                    }
                    .onDelete { offsets in
                        viewModel.deleteNotes(at: offsets, in: date)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut, value: viewModel.filteredNotes.count)
    }

    private var emptyStateView: some View {
        Group {
            if viewModel.searchText.isEmpty && viewModel.keywordFilter == nil {
                EmptyStateView(
                    icon: "mic.circle",
                    titleKey: "empty_notes_title",
                    subtitleKey: "empty_notes_subtitle"
                )
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    titleKey: "no_search_results_title",
                    subtitleKey: "no_search_results_subtitle",
                    actionKey: "clear_search",
                    action: { viewModel.clearFilters() }
                )
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(NotesListViewModel.SortOrder.allCases) { order in
                Button {
                    viewModel.sortOrder = order
                } label: {
                    HStack {
                        Text(order.localizedLabel)
                        if viewModel.sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityLabel(Text("sort_menu_label"))
        }
    }

    @ViewBuilder
    private func filteredView(for keyword: String) -> some View {
        NotesListView(modelContext: modelContext)
            .onAppear {
                viewModel.applyKeywordFilter(keyword)
            }
    }
}

#Preview {
    NotesListView(modelContext: ModelContext(
        try! ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    ))
    .environment(Router())
}
