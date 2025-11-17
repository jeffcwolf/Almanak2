//
//  EditStageView.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI
import SwiftEditorMD

struct EditStageView: View {
    @EnvironmentObject var appState: AppState
    @State private var transcriptionText = ""
    @State private var metadata: [String: String] = [:]
    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            // Info bar
            HStack {
                if let pageIndex = appState.selectedPage {
                    Text("Editing page \(pageIndex + 1) of \(appState.totalPages)")
                        .font(.subheadline)
                }

                Spacer()

                if let project = appState.currentProject {
                    let transcribed = appState.llmManager.transcriptionCount(projectURL: project.url)
                    Text("\(transcribed) / \(appState.totalPages) completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            Divider()

            // Editor
            if isLoading {
                ProgressView("Loading transcription...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                MarkdownEditor(
                    content: $transcriptionText,
                    metadata: $metadata,
                    onSave: { text in
                        saveTranscription(text)
                    },
                    configuration: MarkdownEditorConfig(
                        fontFamily: "SF Mono",
                        defaultFontSize: 14,
                        minFontSize: 10,
                        maxFontSize: 24,
                        autoSaveInterval: 30,
                        enableAutoSave: true,
                        showWordCount: true,
                        showToolbar: true
                    )
                )
            }

            Divider()

            // Navigation bar
            HStack {
                Button {
                    Task {
                        await appState.previousPage()
                        await loadTranscription()
                    }
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(!(appState.selectedPage ?? 0) > 0)

                Spacer()

                Button {
                    manualSave()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(isSaving)

                Spacer()

                Button {
                    Task {
                        await appState.nextPage()
                        await loadTranscription()
                    }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .disabled(!(appState.selectedPage ?? 0) < appState.totalPages - 1)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            // Final navigation
            if let project = appState.currentProject {
                let transcribed = appState.llmManager.transcriptionCount(projectURL: project.url)
                if transcribed == appState.totalPages {
                    HStack {
                        Text("All pages transcribed!")
                            .font(.headline)
                            .foregroundColor(.green)

                        Spacer()

                        Button {
                            appState.advanceStage()
                        } label: {
                            Label("Continue to Export", systemImage: "arrow.right")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                }
            }
        }
        .task {
            await loadTranscription()
        }
        .onChange(of: appState.selectedPage) { _ in
            Task {
                await loadTranscription()
            }
        }
    }

    private func loadTranscription() async {
        guard let project = appState.currentProject,
              let pageIndex = appState.selectedPage else {
            return
        }

        isLoading = true

        do {
            // Try to load existing transcription
            if let existing = try await appState.llmManager.loadEnhancedText(
                pageIndex: pageIndex,
                projectURL: project.url
            ) {
                transcriptionText = existing
            } else {
                // Fall back to OCR result if no transcription exists
                if let ocrResult = try await appState.ocrManager.loadSavedOCRResult(
                    pageIndex: pageIndex,
                    engineType: .vision,
                    projectURL: project.url
                ) {
                    transcriptionText = ocrResult.text
                } else {
                    transcriptionText = ""
                }
            }

            // Set metadata
            metadata = [
                "page": String(pageIndex + 1),
                "title": project.metadata.title,
                "author": project.metadata.author
            ]
        } catch {
            appState.handleError(error)
            transcriptionText = ""
        }

        isLoading = false
    }

    private func saveTranscription(_ text: String) {
        guard let project = appState.currentProject,
              let pageIndex = appState.selectedPage else {
            return
        }

        Task {
            do {
                try await appState.llmManager.saveEnhancedText(
                    text,
                    pageIndex: pageIndex,
                    projectURL: project.url,
                    metadata: metadata
                )

                appState.updateStatus("Page \(pageIndex + 1) saved")
            } catch {
                appState.handleError(error)
            }
        }
    }

    private func manualSave() {
        isSaving = true
        saveTranscription(transcriptionText)

        // Brief delay for user feedback
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isSaving = false
        }
    }
}
