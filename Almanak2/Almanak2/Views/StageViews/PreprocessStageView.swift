//
//  PreprocessStageView.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI

struct PreprocessStageView: View {
    @EnvironmentObject var appState: AppState
    @State private var options = PreprocessOptions.documentOCRPreset
    @State private var showingPreview = false
    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Image Preprocessing")
                .font(.title2)

            Text("Enhance images for better OCR accuracy (optional)")
                .foregroundColor(.secondary)

            // Preset selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Preset")
                    .font(.headline)

                Picker("Preset", selection: $options.presetType) {
                    ForEach(PreprocessOptions.PresetType.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: options.presetType) { newValue in
                    options.applyPreset(newValue)
                }

                Text(options.presetType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Custom options toggle
            Toggle("Custom Options", isOn: Binding(
                get: { !options.usePreset },
                set: { options.usePreset = !$0 }
            ))

            if !options.usePreset {
                CustomPreprocessOptions(options: $options)
            }

            Divider()

            // Preview button
            Button {
                showPreview()
            } label: {
                Label("Preview Current Page", systemImage: "eye")
                    .frame(maxWidth: .infinity)
            }
            .disabled(appState.documentManager.currentPageImage == nil || isProcessing)

            // Process buttons
            HStack(spacing: 12) {
                Button {
                    processCurrentPage()
                } label: {
                    Label("Process Current Page", systemImage: "wand.and.stars")
                }
                .disabled(appState.selectedPage == nil || isProcessing)

                Button {
                    processAllPages()
                } label: {
                    Label("Process All Pages", systemImage: "wand.and.stars.inverse")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }

            if isProcessing {
                ProgressView("Processing...")
                    .frame(maxWidth: .infinity)
            }

            Spacer()

            // Navigation
            HStack {
                Button {
                    appState.advanceStage()
                } label: {
                    Label("Skip Preprocessing", systemImage: "arrow.right")
                }

                Spacer()

                if let project = appState.currentProject {
                    let preprocessed = appState.preprocessingManager.preprocessedPageCount(projectURL: project.url)
                    if preprocessed > 0 {
                        Button {
                            appState.advanceStage()
                        } label: {
                            Label("Continue (\(preprocessed) processed)", systemImage: "arrow.right")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            PreviewSheet(
                before: appState.preprocessingManager.beforeImage,
                after: appState.preprocessingManager.afterImage
            )
        }
    }

    private func showPreview() {
        guard let image = appState.documentManager.currentPageImage else { return }

        Task {
            do {
                try await appState.preprocessingManager.previewPreprocessing(
                    image: image,
                    options: options
                )
                showingPreview = true
            } catch {
                appState.handleError(error)
            }
        }
    }

    private func processCurrentPage() {
        guard let pageIndex = appState.selectedPage,
              let project = appState.currentProject else { return }

        isProcessing = true

        Task {
            do {
                try await appState.preprocessingManager.preprocessPage(
                    pageIndex: pageIndex,
                    projectURL: project.url,
                    options: options
                )

                // Reload page to show preprocessed version
                await appState.goToPage(pageIndex)

                appState.updateStatus("Page \(pageIndex + 1) preprocessed")
            } catch {
                appState.handleError(error)
            }

            isProcessing = false
        }
    }

    private func processAllPages() {
        guard let project = appState.currentProject else { return }

        isProcessing = true

        Task {
            do {
                try await appState.preprocessingManager.preprocessAllPages(
                    projectURL: project.url,
                    options: options
                ) { current, total in
                    appState.updateProgress(current, total, message: "Preprocessing page \(current) of \(total)")
                }

                // Reload current page
                if let selected = appState.selectedPage {
                    await appState.goToPage(selected)
                }

                appState.updateStatus("All pages preprocessed")
            } catch {
                appState.handleError(error)
            }

            isProcessing = false
        }
    }
}

struct CustomPreprocessOptions: View {
    @Binding var options: PreprocessOptions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Grayscale", isOn: $options.grayscale)

            Toggle("Deskew", isOn: $options.deskew)
            if options.deskew {
                HStack {
                    Text("Tolerance:")
                    Slider(value: $options.deskewTolerance, in: 1...10, step: 1)
                    Text("\(Int(options.deskewTolerance))°")
                        .frame(width: 30)
                }
                .font(.caption)
            }

            Toggle("Denoise", isOn: $options.denoise)
            if options.denoise {
                HStack {
                    Text("Radius:")
                    Slider(value: $options.denoiseRadius, in: 1...5, step: 0.5)
                    Text(String(format: "%.1f", options.denoiseRadius))
                        .frame(width: 30)
                }
                .font(.caption)
            }

            Toggle("Enhance Contrast", isOn: $options.enhanceContrast)
            Toggle("Binarize", isOn: $options.binarize)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PreviewSheet: View {
    @Environment(\.dismiss) var dismiss
    let before: NSImage?
    let after: NSImage?

    var body: some View {
        VStack {
            Text("Preprocessing Preview")
                .font(.title2)
                .padding()

            HStack(spacing: 20) {
                VStack {
                    Text("Before")
                        .font(.headline)

                    if let before = before {
                        Image(nsImage: before)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 400, maxHeight: 500)
                    }
                }

                Divider()

                VStack {
                    Text("After")
                        .font(.headline)

                    if let after = after {
                        Image(nsImage: after)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 400, maxHeight: 500)
                    }
                }
            }
            .padding()

            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .padding()
        }
        .frame(width: 900, height: 700)
    }
}
