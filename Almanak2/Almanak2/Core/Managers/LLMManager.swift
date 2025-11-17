//
//  LLMManager.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation
import SwiftLLM

/// Manages LLM operations using SwiftLLM
@MainActor
class LLMManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isAvailable = false
    @Published var originalText = ""
    @Published var enhancedText = ""
    @Published var isProcessing = false
    @Published var availableModels: [LLMModel] = []
    @Published var selectedModel: LLMModel?

    // MARK: - Private Properties
    private var provider: OllamaProvider?
    private var service: LLMService?

    // MARK: - Initialization

    init() {
        Task {
            await checkAvailability()
        }
    }

    // MARK: - Availability Check

    /// Check if Ollama LLM is available
    func checkAvailability() async {
        do {
            let ollama = OllamaProvider()
            let connected = try await ollama.testConnection()

            if connected {
                provider = ollama
                isAvailable = true

                // Get available models
                availableModels = try await ollama.availableModels

                // Select default model (prefer llama3)
                if let llama3 = availableModels.first(where: { $0.id.contains("llama3") }) {
                    selectedModel = llama3
                    service = LLMService(provider: ollama, defaultModel: llama3)
                } else if let firstModel = availableModels.first {
                    selectedModel = firstModel
                    service = LLMService(provider: ollama, defaultModel: firstModel)
                }
            } else {
                isAvailable = false
            }
        } catch {
            isAvailable = false
            provider = nil
            service = nil
        }
    }

    // MARK: - Model Selection

    /// Select a specific model to use
    func selectModel(_ model: LLMModel) {
        guard let provider = provider else { return }
        selectedModel = model
        service = LLMService(provider: provider, defaultModel: model)
    }

    // MARK: - Text Enhancement

    /// Enhance OCR text (general improvement)
    func enhanceOCRText(
        _ rawText: String,
        language: String = "en",
        context: String? = nil
    ) async throws -> String {
        guard let service = service else {
            throw AlmanakError.llmUnavailable
        }

        guard isAvailable else {
            throw AlmanakError.llmUnavailable
        }

        isProcessing = true
        originalText = rawText
        defer { isProcessing = false }

        do {
            enhancedText = try await service.enhanceOCRText(
                rawText,
                language: language,
                context: context ?? "Historical document from 18th century"
            )

            return enhancedText
        } catch {
            throw AlmanakError.enhancementFailed(error.localizedDescription)
        }
    }

    /// Correct OCR errors only (minimal changes)
    func correctOCRErrors(
        _ text: String,
        language: String = "en"
    ) async throws -> String {
        guard let service = service else {
            throw AlmanakError.llmUnavailable
        }

        guard isAvailable else {
            throw AlmanakError.llmUnavailable
        }

        isProcessing = true
        originalText = text
        defer { isProcessing = false }

        do {
            enhancedText = try await service.correctOCRErrors(text, language: language)
            return enhancedText
        } catch {
            throw AlmanakError.enhancementFailed(error.localizedDescription)
        }
    }

    /// Generic text completion (for custom prompts)
    func complete(prompt: String, options: CompletionOptions = .default) async throws -> String {
        guard let service = service else {
            throw AlmanakError.llmUnavailable
        }

        guard isAvailable else {
            throw AlmanakError.llmUnavailable
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await service.complete(
                prompt: prompt,
                options: options
            )
            return response.text
        } catch {
            throw AlmanakError.enhancementFailed(error.localizedDescription)
        }
    }

    // MARK: - Saving/Loading

    /// Save enhanced text to transcription directory
    func saveEnhancedText(
        _ text: String,
        pageIndex: Int,
        projectURL: URL,
        metadata: [String: String]? = nil
    ) async throws {
        let transcriptionDir = projectURL.appendingPathComponent("transcription")
        let fileURL = transcriptionDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).md"
        )

        // Optionally add frontmatter if metadata provided
        var content = text
        if let metadata = metadata, !metadata.isEmpty {
            var frontmatter = "---\n"
            for (key, value) in metadata {
                frontmatter += "\(key): \(value)\n"
            }
            frontmatter += "---\n\n"
            content = frontmatter + text
        }

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Load enhanced text from transcription directory
    func loadEnhancedText(pageIndex: Int, projectURL: URL) async throws -> String? {
        let transcriptionDir = projectURL.appendingPathComponent("transcription")
        let fileURL = transcriptionDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).md"
        )

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    /// Check if transcription exists for a page
    func hasTranscription(for pageIndex: Int, projectURL: URL) -> Bool {
        let transcriptionDir = projectURL.appendingPathComponent("transcription")
        let fileURL = transcriptionDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).md"
        )

        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Get count of transcribed pages
    func transcriptionCount(projectURL: URL) -> Int {
        let transcriptionDir = projectURL.appendingPathComponent("transcription")

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: transcriptionDir,
            includingPropertiesForKeys: nil
        ) else {
            return 0
        }

        return files.filter { $0.pathExtension == "md" }.count
    }

    // MARK: - Streaming Support

    /// Stream text completion (for real-time preview)
    func streamCompletion(
        prompt: String,
        options: CompletionOptions = .default,
        onChunk: @escaping (String) -> Void
    ) async throws {
        guard let service = service else {
            throw AlmanakError.llmUnavailable
        }

        guard isAvailable else {
            throw AlmanakError.llmUnavailable
        }

        isProcessing = true
        defer { isProcessing = false }

        let stream = service.stream(prompt: prompt, options: options)

        do {
            for try await chunk in stream {
                onChunk(chunk)
            }
        } catch {
            throw AlmanakError.enhancementFailed(error.localizedDescription)
        }
    }

    // MARK: - Utilities

    /// Get connection status description
    var statusDescription: String {
        if isAvailable {
            return "Connected to Ollama"
        } else {
            return "Ollama not available"
        }
    }

    /// Get selected model name
    var selectedModelName: String {
        selectedModel?.name ?? "No model selected"
    }

    // MARK: - Cleanup

    func reset() {
        originalText = ""
        enhancedText = ""
        isProcessing = false
    }
}
