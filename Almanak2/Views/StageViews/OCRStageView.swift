//
//  OCRStageView.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI

struct OCRStageView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedEngines: Set<OCREngineType> = [.vision]
    @State private var isProcessing = false
    @State private var showingEnhancement = false
    @State private var useEnhancement = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("OCR & Enhancement")
                .font(.title2)

            // Engine selection
            VStack(alignment: .leading, spacing: 8) {
                Text("OCR Engine")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { selectedEngines.contains(.vision) },
                        set: { if $0 { selectedEngines.insert(.vision) } else { selectedEngines.remove(.vision) } }
                    )) {
                        HStack {
                            Image(systemName: OCREngineType.vision.systemImage)
                            VStack(alignment: .leading) {
                                Text(OCREngineType.vision.displayName)
                                Text(OCREngineType.vision.estimatedSpeed)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Toggle(isOn: Binding(
                        get: { selectedEngines.contains(.ollama) },
                        set: { if $0 { selectedEngines.insert(.ollama) } else { selectedEngines.remove(.ollama) } }
                    )) {
                        HStack {
                            Image(systemName: OCREngineType.ollama.systemImage)
                            VStack(alignment: .leading) {
                                Text(OCREngineType.ollama.displayName)
                                Text(OCREngineType.ollama.estimatedSpeed)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(!appState.ocrManager.ollamaAvailable)

                    if !appState.ocrManager.ollamaAvailable {
                        Text("Ollama not available. Install and start Ollama to use.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Divider()

            // Run OCR button
            Button {
                runOCR()
            } label: {
                Label("Run OCR on Current Page", systemImage: "doc.text.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedEngines.isEmpty || appState.selectedPage == nil || isProcessing)

            // Results display
            if let visionResult = appState.ocrManager.visionResult,
               let ollamaResult = appState.ocrManager.ollamaResult {
                // Comparison mode (two panels)
                OCRComparisonView(
                    visionResult: visionResult,
                    ollamaResult: ollamaResult,
                    onSelect: { result in
                        appState.ocrManager.selectResult(result)
                        showingEnhancement = true
                    }
                )
            } else if let result = appState.ocrManager.visionResult ?? appState.ocrManager.ollamaResult {
                // Single result
                OCRResultView(result: result) {
                    appState.ocrManager.selectResult(result)
                    showingEnhancement = true
                }
            }

            // Enhancement section
            if showingEnhancement, let selected = appState.ocrManager.selectedResult {
                Divider()

                EnhancementSection(
                    rawText: selected.text,
                    useEnhancement: $useEnhancement,
                    onSave: { finalText in
                        saveTranscription(finalText)
                    }
                )
            }

            if isProcessing {
                ProgressView("Processing...")
                    .frame(maxWidth: .infinity)
            }

            Spacer()

            // Navigation
            if let project = appState.currentProject {
                let transcribed = appState.llmManager.transcriptionCount(projectURL: project.url)
                if transcribed > 0 {
                    HStack {
                        Text("\(transcribed) / \(appState.totalPages) pages transcribed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button {
                            appState.advanceStage()
                        } label: {
                            Label("Continue to Editing", systemImage: "arrow.right")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }

    private func runOCR() {
        guard let pageIndex = appState.selectedPage,
              let project = appState.currentProject else { return }

        isProcessing = true

        Task {
            do {
                try await appState.ocrManager.performOCROnPage(
                    pageIndex: pageIndex,
                    projectURL: project.url,
                    engines: selectedEngines
                )

                appState.updateStatus("OCR complete for page \(pageIndex + 1)")

                // If only one engine, auto-select the result
                if selectedEngines.count == 1 {
                    if let result = appState.ocrManager.visionResult ?? appState.ocrManager.ollamaResult {
                        appState.ocrManager.selectResult(result)
                        showingEnhancement = true
                    }
                }
            } catch {
                appState.handleError(error)
            }

            isProcessing = false
        }
    }

    private func saveTranscription(_ text: String) {
        guard let pageIndex = appState.selectedPage,
              let project = appState.currentProject else { return }

        Task {
            do {
                let metadata = [
                    "page": String(pageIndex + 1),
                    "ocrEngine": appState.ocrManager.selectedResult?.engine ?? "unknown",
                    "enhanced": useEnhancement ? "yes" : "no"
                ]

                try await appState.llmManager.saveEnhancedText(
                    text,
                    pageIndex: pageIndex,
                    projectURL: project.url,
                    metadata: metadata
                )

                appState.updateStatus("Transcription saved for page \(pageIndex + 1)")

                // Reset for next page
                showingEnhancement = false
                appState.ocrManager.reset()

                // Auto-advance to next page
                if pageIndex < appState.totalPages - 1 {
                    await appState.nextPage()
                }
            } catch {
                appState.handleError(error)
            }
        }
    }
}

struct OCRResultView: View {
    let result: OCRResult
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.engine)
                    .font(.headline)

                Spacer()

                Text("Confidence: \(Int(result.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(result.confidence > 0.8 ? .green : .orange)
            }

            ScrollView {
                Text(result.text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            Button {
                onSelect()
            } label: {
                Label("Use This Result", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct OCRComparisonView: View {
    let visionResult: OCRResult
    let ollamaResult: OCRResult
    let onSelect: (OCRResult) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Compare Results")
                .font(.headline)

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    CompactResultView(result: visionResult) {
                        onSelect(visionResult)
                    }
                }

                VStack(alignment: .leading) {
                    CompactResultView(result: ollamaResult) {
                        onSelect(ollamaResult)
                    }
                }
            }
        }
    }
}

struct CompactResultView: View {
    let result: OCRResult
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.engine)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Conf: \(Int(result.confidence * 100))%")
                .font(.caption)
                .foregroundColor(result.confidence > 0.8 ? .green : .orange)

            ScrollView {
                Text(result.text)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150)
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)

            Button {
                onSelect()
            } label: {
                Text("Use This")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

struct EnhancementSection: View {
    @EnvironmentObject var appState: AppState
    let rawText: String
    @Binding var useEnhancement: Bool
    let onSave: (String) -> Void

    @State private var enhancedText = ""
    @State private var isEnhancing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enhancement")
                .font(.headline)

            Toggle(isOn: $useEnhancement) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Enhance with LLM")
                    if !appState.llmManager.isAvailable {
                        Text("(Not available)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .disabled(!appState.llmManager.isAvailable)

            if useEnhancement {
                Button {
                    enhanceText()
                } label: {
                    Label("Preview Enhancement", systemImage: "eye")
                }
                .disabled(isEnhancing)

                if isEnhancing {
                    ProgressView("Enhancing...")
                }

                if !enhancedText.isEmpty {
                    ScrollView {
                        Text(enhancedText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: 150)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            Button {
                onSave(useEnhancement && !enhancedText.isEmpty ? enhancedText : rawText)
            } label: {
                Label("Save & Continue", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    private func enhanceText() {
        isEnhancing = true

        Task {
            do {
                enhancedText = try await appState.llmManager.enhanceOCRText(rawText)
            } catch {
                appState.handleError(error)
            }

            isEnhancing = false
        }
    }
}
