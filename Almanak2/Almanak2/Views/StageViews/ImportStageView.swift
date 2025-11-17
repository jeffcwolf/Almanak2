//
//  ImportStageView.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportStageView: View {
    @EnvironmentObject var appState: AppState
    @State private var sourceType: SourceType = .pdf
    @State private var isImporting = false
    @State private var showingFilePicker = false

    enum SourceType {
        case pdf
        case imageFolder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Import Source Document")
                .font(.title2)

            // Source type picker
            Picker("Source Type", selection: $sourceType) {
                Text("PDF File").tag(SourceType.pdf)
                Text("Image Folder").tag(SourceType.imageFolder)
            }
            .pickerStyle(.segmented)

            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                if sourceType == .pdf {
                    Label("Select a PDF file to extract pages", systemImage: "doc.fill")
                } else {
                    Label("Select a folder containing images", systemImage: "folder.fill")
                }

                Text("Supported formats: PDF, JP2, PNG, JPEG, TIFF, GIF, BMP, WebP, HEIC")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // File picker button
            Button {
                showingFilePicker = true
            } label: {
                Label(sourceType == .pdf ? "Choose PDF File" : "Choose Image Folder", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)

            // Drop zone
            Text("Or drag and drop here")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.gray.opacity(0.3))
                )
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers)
                    return true
                }

            if isImporting {
                ProgressView("Importing...")
                    .frame(maxWidth: .infinity)
            }

            Spacer()

            // Navigation
            if appState.totalPages > 0 {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Import Complete")
                            .font(.headline)
                        Text("\(appState.totalPages) pages imported")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        appState.advanceStage()
                    } label: {
                        Label("Continue", systemImage: "arrow.right")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: sourceType == .pdf ? [.pdf] : [.folder],
            allowsMultipleSelection: sourceType == .imageFolder
        ) { result in
            handleFileSelection(result)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first,
                  let project = appState.currentProject else { return }

            importSource(url, projectURL: project.url)

        case .failure(let error):
            appState.handleError(error)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        guard let provider = providers.first,
              let project = appState.currentProject else { return }

        _ = provider.loadObject(ofClass: URL.self) { url, error in
            if let url = url {
                DispatchQueue.main.async {
                    importSource(url, projectURL: project.url)
                }
            }
        }
    }

    private func importSource(_ url: URL, projectURL: URL) {
        isImporting = true

        Task {
            do {
                if sourceType == .pdf {
                    appState.updateStatus("Importing PDF...")
                    try await appState.documentManager.importPDF(from: url, projectURL: projectURL)
                } else {
                    appState.updateStatus("Importing images...")
                    let imageURLs = try collectImageURLs(from: url)
                    try await appState.documentManager.importImages(from: imageURLs, projectURL: projectURL)
                }

                // Load first page
                await appState.goToPage(0)

                appState.updateStatus("Import complete: \(appState.totalPages) pages")
            } catch {
                appState.handleError(error)
            }

            isImporting = false
        }
    }

    private func collectImageURLs(from folderURL: URL) throws -> [URL] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil
        )

        let imageExtensions = ["jp2", "png", "jpg", "jpeg", "tif", "tiff", "gif", "bmp", "webp", "heic"]
        let imageURLs = contents.filter { url in
            imageExtensions.contains(url.pathExtension.lowercased())
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !imageURLs.isEmpty else {
            throw AlmanakError.imageImportFailed("No image files found in folder")
        }

        return imageURLs
    }
}
