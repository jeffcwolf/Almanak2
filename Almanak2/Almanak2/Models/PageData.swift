//
//  PageData.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation

/// Represents data for a single page in the transcription project
struct PageData: Identifiable, Codable {
    let id: UUID
    let index: Int

    // MARK: - File URLs
    var originalImageURL: URL?
    var preprocessedImageURL: URL?
    var visionOCRURL: URL?
    var ollamaOCRURL: URL?
    var transcriptionURL: URL?

    // MARK: - Processing State
    var selectedEngine: OCREngineType?
    var llmEnhanced: Bool
    var confidence: Double?
    var completed: Bool
    var preprocessed: Bool

    // MARK: - Timestamps
    var lastModified: Date?

    // MARK: - Initialization
    init(index: Int) {
        self.id = UUID()
        self.index = index
        self.llmEnhanced = false
        self.completed = false
        self.preprocessed = false
        self.lastModified = Date()
    }

    // MARK: - Helper Methods

    /// Returns the best available image URL (preprocessed if available, otherwise original)
    var bestImageURL: URL? {
        preprocessedImageURL ?? originalImageURL
    }

    /// Returns the selected OCR result URL
    var selectedOCRURL: URL? {
        guard let engine = selectedEngine else { return nil }
        return engine == .vision ? visionOCRURL : ollamaOCRURL
    }

    /// Check if OCR has been performed
    var hasOCR: Bool {
        visionOCRURL != nil || ollamaOCRURL != nil
    }

    /// Check if transcription exists
    var hasTranscription: Bool {
        transcriptionURL != nil
    }

    /// Display string for page number
    var displayNumber: String {
        "Page \(index + 1)"
    }

    /// Completion percentage (0.0 to 1.0)
    var completionProgress: Double {
        var progress = 0.0
        if originalImageURL != nil { progress += 0.2 }
        if hasOCR { progress += 0.4 }
        if hasTranscription { progress += 0.4 }
        return progress
    }
}
