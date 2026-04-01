// NoteChain/Features/NotesList/NoteDetailView.swift
// ノート詳細・インライン編集・キーワード管理画面

import SwiftData
import SwiftUI

/// ノートの詳細を表示し、インライン編集・キーワード追加削除・削除ができる画面。
struct NoteDetailView: View {

    @State private var viewModel: NoteDetailViewModel
    @Environment(Router.self) private var router
    @State private var showDeleteConfirm = false

    init(noteID: UUID, modelContext: ModelContext) {
        _viewModel = State(
            wrappedValue: NoteDetailViewModel(noteID: noteID, modelContext: modelContext)
        )
    }

    var body: some View {
        Group {
            if let note = viewModel.note {
                noteContent(note)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { viewModel.loadNote() }
        .onChange(of: viewModel.isDeleted) { _, deleted in
            if deleted { router.pop(from: .notes) }
        }
        .alert("error_title",
               isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
               )) {
            Button("ok_button", role: .cancel) { viewModel.clearError() }
        } message: {
            if let msg = viewModel.errorMessage { Text(msg) }
        }
        .confirmationDialog("delete_note_confirm_title",
                             isPresented: $showDeleteConfirm,
                             titleVisibility: .visible) {
            Button("delete_button", role: .destructive) { viewModel.deleteNote() }
            Button("cancel_button", role: .cancel) {}
        } message: {
            Text("delete_note_confirm_body")
        }
    }

    // MARK: - メインコンテンツ

    @ViewBuilder
    private func noteContent(_ note: Note) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // メタ情報
                metaInfo(note)

                Divider()

                // 文字起こしテキスト
                transcriptSection(note)

                Divider()

                // キーワードセクション
                keywordsSection(note)
            }
            .padding()
        }
        .navigationTitle(note.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // お気に入りボタン
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: note.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(note.isFavorite ? .red : .secondary)
                }
                .accessibilityLabel(note.isFavorite ? "unfavorite_button" : "favorite_button")

                // 編集ボタン
                if !viewModel.isEditing {
                    Button("edit_button") { viewModel.startEditing() }
                }

                // 削除ボタン
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel(Text("delete_button"))
            }
        }
        .overlay {
            if viewModel.isExtractingKeywords {
                LoadingOverlay(message: "extracting_keywords")
            }
        }
    }

    // MARK: - メタ情報

    private func metaInfo(_ note: Note) -> some View {
        HStack(spacing: 16) {
            Label(note.createdAt.sectionHeaderFormatted, systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
            Label(note.formattedDuration, systemImage: "waveform")
                .font(.caption)
                .foregroundStyle(.secondary)
            Label("\(note.wordCount) \(String(localized: "words_label"))", systemImage: "text.word.spacing")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - 文字起こしセクション

    @ViewBuilder
    private func transcriptSection(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("transcript_section_title")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            if viewModel.isEditing {
                TextEditor(text: $viewModel.editingTranscript)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

                HStack {
                    Button("cancel_button") { viewModel.cancelEdit() }
                        .buttonStyle(.bordered)
                    Spacer()
                    Button("save_button") {
                        Task { await viewModel.saveEdit() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text(note.transcript)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - キーワードセクション

    @ViewBuilder
    private func keywordsSection(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("keywords_section_title")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    Task { await viewModel.reExtractKeywords() }
                } label: {
                    Label("re_extract_button", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
            }

            // 既存キーワードバッジ
            if !note.keywords.isEmpty {
                KeywordBadgesRow(
                    keywords: note.keywords,
                    confidences: note.keywordConfidences,
                    isEditable: true,
                    onDelete: { viewModel.removeKeyword($0) }
                )
            } else {
                Text("no_keywords_message")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // キーワード追加
            HStack {
                TextField("add_keyword_placeholder", text: $viewModel.newKeywordText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .submitLabel(.done)
                    .onSubmit { viewModel.addKeyword(viewModel.newKeywordText) }
                Button("add_button") {
                    viewModel.addKeyword(viewModel.newKeywordText)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                .disabled(viewModel.newKeywordText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(
            noteID: UUID(),
            modelContext: ModelContext(
                try! ModelContainer(
                    for: Note.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            )
        )
        .environment(Router())
    }
}
