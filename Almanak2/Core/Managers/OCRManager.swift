//
//  OCRManager.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation
import AppKit
import SwiftOCR

/// Manages OCR operations using SwiftOCR
@MainActor
class OCRManager: ObservableObject {
    // MARK: - Published Properties
    @Published var visionResult: OCRResult?
    @Published var ollamaResult: OCRResult?
    @Published var selectedResult: OCRResult?
    @Published var isProcessing = false
    @Published var ollamaAvailable = false

    // MARK: - Private Properties
    private let visionEngine: VisionOCREngine
    private var ollamaEngine: OllamaOCREngine?
    private var visionService: OCRService
    private var ollamaService: OCRService?

    // MARK: - Initialization

    init() {
        // Initialize Vision engine (always available)
        self.visionEngine = VisionOCREngine(recognitionLevel: .accurate)
        self.visionService = OCRService(engine: visionEngine)

        // Try to initialize Ollama (optional)
        Task {
            await checkOllamaAvailability()
        }
    }

    // MARK: - Availability Check

    /// Check if Ollama is available
    func checkOllamaAvailability() async {
        do {
            let engine = OllamaOCREngine(
                baseURL: URL(string: "http://localhost:11434")!,
                model: "llava"
            )

            // Test connection (assuming there's a way to test it)
            // For now, just try to create it
            self.ollamaEngine = engine
            self.ollamaService = OCRService(engine: engine)
            ollamaAvailable = true
        } catch {
            ollamaAvailable = false
        }
    }

    // MARK: - OCR Processing

    /// Perform OCR on an image with selected engines
    func performOCR(
        on image: NSImage,
        engines: Set<OCREngineType>,
        language: String = "en"
    ) async throws {
        isProcessing = true
        defer { isProcessing = false }

        visionResult = nil
        ollamaResult = nil

        let options = OCROptions(
            recognitionLevel: .accurate,
            minimumConfidence: 0.0,
            extractRegions: true,
            correctOrientation: true
        )

        // Run Vision OCR
        if engines.contains(.vision) {
            do {
                visionResult = try await visionService.recognize(
                    image: image,
                    language: language,
                    options: options
                )
            } catch {
                throw AlmanakError.ocrFailed(0, "Vision OCR failed: \(error.localizedDescription)")
            }
        }

        // Run Ollama OCR if available and selected
        if engines.contains(.ollama) {
            guard ollamaAvailable, let ollamaService = ollamaService else {
                throw AlmanakError.engineUnavailable("Ollama")
            }

            do {
                ollamaResult = try await ollamaService.recognize(
                    image: image,
                    language: language,
                    options: options
                )
            } catch {
                throw AlmanakError.ocrFailed(0, "Ollama OCR failed: \(error.localizedDescription)")
            }
        }
    }

    /// Perform OCR on a page from project
    func performOCROnPage(
        pageIndex: Int,
        projectURL: URL,
        engines: Set<OCREngineType>,
        language: String = "en"
    ) async throws {
        // Determine which image to use (preprocessed if exists, otherwise original)
        let preprocessedDir = projectURL.appendingPathComponent("preprocessed")
        let pagesDir = projectURL.appendingPathComponent("pages")

        var imageURL: URL?

        // Try preprocessed first
        if let preprocessedFiles = try? FileManager.default.contentsOfDirectory(
            at: preprocessedDir,
            includingPropertiesForKeys: nil
        ) {
            imageURL = preprocessedFiles.first(where: {
                $0.lastPathComponent.contains(String(format: "%03d", pageIndex))
            })
        }

        // Fall back to original
        if imageURL == nil {
            let pageFiles = try FileManager.default.contentsOfDirectory(
                at: pagesDir,
                includingPropertiesForKeys: nil
            )
            imageURL = pageFiles.first(where: {
                $0.lastPathComponent.contains(String(format: "%03d", pageIndex))
            })
        }

        guard let url = imageURL,
              let image = NSImage(contentsOf: url) else {
            throw AlmanakError.fileNotFound(pagesDir.appendingPathComponent("page_\(pageIndex)"))
        }

        try await performOCR(on: image, engines: engines, language: language)
    }

    // MARK: - Result Selection

    /// Select a result as the final OCR output
    func selectResult(_ result: OCRResult) {
        selectedResult = result
    }

    /// Select Vision result
    func selectVisionResult() {
        selectedResult = visionResult
    }

    /// Select Ollama result
    func selectOllamaResult() {
        selectedResult = ollamaResult
    }

    // MARK: - Saving

    /// Save OCR result to disk
    func saveOCRResult(
        _ result: OCRResult,
        pageIndex: Int,
        projectURL: URL
    ) async throws {
        // Determine engine directory
        let engineDir = result.engine == "Vision" ? "vision" : "ollama"
        let ocrDir = projectURL
            .appendingPathComponent("ocr")
            .appendingPathComponent(engineDir)

        // Save text result
        let resultURL = ocrDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).txt"
        )
        try result.text.write(to: resultURL, atomically: true, encoding: .utf8)

        // Save metadata
        let metadataURL = ocrDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).json"
        )

        let metadata: [String: Any] = [
            "confidence": result.confidence,
            "language": result.language ?? "unknown",
            "processingTime": result.processingTime,
            "engine": result.engine,
            "regionsCount": result.regions?.count ?? 0,
            "timestamp": Date().timeIntervalSince1970
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        try jsonData.write(to: metadataURL)
    }

    /// Save selected result
    func saveSelectedResult(pageIndex: Int, projectURL: URL) async throws {
        guard let result = selectedResult else {
            throw AlmanakError.noOCRResult
        }

        try await saveOCRResult(result, pageIndex: pageIndex, projectURL: projectURL)
    }

    // MARK: - Loading

    /// Load saved OCR result
    func loadSavedOCRResult(
        pageIndex: Int,
        engineType: OCREngineType,
        projectURL: URL
    ) async throws -> OCRResult? {
        let engineDir = engineType.directoryName
        let ocrDir = projectURL
            .appendingPathComponent("ocr")
            .appendingPathComponent(engineDir)

        let resultURL = ocrDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).txt"
        )

        guard FileManager.default.fileExists(atPath: resultURL.path) else {
            return nil
        }

        let text = try String(contentsOf: resultURL, encoding: .utf8)

        // Load metadata if available
        let metadataURL = ocrDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).json"
        )

        var confidence = 0.0
        var language: String?
        var processingTime: TimeInterval = 0

        if let jsonData = try? Data(contentsOf: metadataURL),
           let metadata = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            confidence = metadata["confidence"] as? Double ?? 0.0
            language = metadata["language"] as? String
            processingTime = metadata["processingTime"] as? TimeInterval ?? 0
        }

        return OCRResult(
            text: text,
            confidence: confidence,
            regions: nil,
            language: language,
            processingTime: processingTime,
            engine: engineType.shortName
        )
    }

    // MARK: - Utilities

    /// Check if OCR has been performed on a page
    func hasOCRResult(for pageIndex: Int, engine: OCREngineType, projectURL: URL) -> Bool {
        let ocrDir = projectURL
            .appendingPathComponent("ocr")
            .appendingPathComponent(engine.directoryName)

        let resultURL = ocrDir.appendingPathComponent(
            "page_\(String(format: "%03d", pageIndex)).txt"
        )

        return FileManager.default.fileExists(atPath: resultURL.path)
    }

    /// Get count of pages with OCR results
    func ocrPageCount(for engine: OCREngineType, projectURL: URL) -> Int {
        let ocrDir = projectURL
            .appendingPathComponent("ocr")
            .appendingPathComponent(engine.directoryName)

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: ocrDir,
            includingPropertiesForKeys: nil
        ) else {
            return 0
        }

        return files.filter { $0.pathExtension == "txt" }.count
    }

    // MARK: - Cleanup

    func reset() {
        visionResult = nil
        ollamaResult = nil
        selectedResult = nil
        isProcessing = false
    }
}
