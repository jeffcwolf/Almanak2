//
//  ExportStageView.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI

struct ExportStageView: View {
    @EnvironmentObject var appState: AppState
    @State private var includeMetadata = true
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showingPreview = false
    @State private var previewText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Export Transcription")
                .font(.title2)

            // Completion status
            if let project = appState.currentProject {
                let transcribed = appState.llmManager.transcriptionCount(projectURL: project.url)
                let total = appState.totalPages

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transcription Status")
                            .font(.headline)

                        Spacer()

                        if transcribed == total {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    ProgressView(value: Double(transcribed), total: Double(total))

                    Text("\(transcribed) of \(total) pages transcribed")
                        .font(.subheadline)
                        .foregroundColor(transcribed == total ? .green : .orange)

                    if transcribed < total {
                        Text("Some pages are not yet transcribed. The export will only include completed pages.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            Divider()

            // Export options
            VStack(alignment: .leading, spacing: 12) {
                Text("Export Options")
                    .font(.headline)

                Toggle("Include Metadata (YAML frontmatter)", isOn: $includeMetadata)

                Text("Format: Markdown (.md)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Preview button
            Button {
                generatePreview()
            } label: {
                Label("Preview Combined Document", systemImage: "eye")
                    .frame(maxWidth: .infinity)
            }
            .disabled(isExporting)

            // Export button
            Button {
                exportDocument()
            } label: {
                Label("Export Markdown File", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)

            if isExporting {
                ProgressView("Exporting...")
                    .frame(maxWidth: .infinity)
            }

            // Success message
            if let url = exportedURL {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Text("Export Complete!")
                            .font(.headline)
                            .foregroundColor(.green)
                    }

                    Text("Saved to: \(url.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                        } label: {
                            Label("Show in Finder", systemImage: "folder")
                        }

                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Label("Open File", systemImage: "doc.text")
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()
        }
        .sheet(isPresented: $showingPreview) {
            PreviewDocumentSheet(text: previewText)
        }
    }

    private func generatePreview() {
        guard let project = appState.currentProject else { return }

        Task {
            do {
                let combined = try await combineTranscriptions(
                    projectURL: project.url,
                    includeMetadata: includeMetadata
                )
                previewText = combined
                showingPreview = true
            } catch {
                appState.handleError(error)
            }
        }
    }

    private func exportDocument() {
        guard let project = appState.currentProject else { return }

        isExporting = true

        Task {
            do {
                // Combine all transcriptions
                let combined = try await combineTranscriptions(
                    projectURL: project.url,
                    includeMetadata: includeMetadata
                )

                // Generate output filename
                let filename = "\(project.metadata.title.replacingOccurrences(of: " ", with: "_"))_transcription.md"
                let outputURL = project.url.appendingPathComponent(filename)

                // Write to file
                try combined.write(to: outputURL, atomically: true, encoding: .utf8)

                exportedURL = outputURL
                appState.updateStatus("Export complete: \(filename)")
            } catch {
                appState.handleError(error)
            }

            isExporting = false
        }
    }

    private func combineTranscriptions(
        projectURL: URL,
        includeMetadata: Bool
    ) async throws -> String {
        let transcriptionDir = projectURL.appendingPathComponent("transcription")

        let files = try FileManager.default.contentsOfDirectory(
            at: transcriptionDir,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "md" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var combined = ""

        // Add global metadata
        if includeMetadata, let project = appState.currentProject {
            combined += """
            ---
            title: \(project.metadata.title)
            author: \(project.metadata.author)
            date: \(project.metadata.publicationDate ?? "")
            pages: \(files.count)
            generated: \(Date().formatted())
            ---

            """
        }

        // Add each page
        for (index, fileURL) in files.enumerated() {
            let content = try String(contentsOf: fileURL, encoding: .utf8)

            // Remove individual page frontmatter if exists
            var pageContent = content
            if content.hasPrefix("---") {
                let components = content.components(separatedBy: "---")
                if components.count >= 3 {
                    pageContent = components[2...].joined(separator: "---")
                }
            }

            combined += "\n\n<!-- Page \(index + 1) -->\n\n"
            combined += pageContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return combined
    }
}

struct PreviewDocumentSheet: View {
    @Environment(\.dismiss) var dismiss
    let text: String

    var body: some View {
        VStack {
            HStack {
                Text("Document Preview")
                    .font(.title2)

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            ScrollView {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(width: 800, height: 600)
    }
}
