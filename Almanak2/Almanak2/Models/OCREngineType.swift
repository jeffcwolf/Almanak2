//
//  OCREngineType.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation

/// Represents available OCR engine types
enum OCREngineType: String, Codable, CaseIterable, Identifiable {
    case vision = "Apple Vision"
    case ollama = "Ollama VLLM"

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        rawValue
    }

    var shortName: String {
        switch self {
        case .vision: return "Vision"
        case .ollama: return "Ollama"
        }
    }

    var systemImage: String {
        switch self {
        case .vision: return "eye.fill"
        case .ollama: return "server.rack"
        }
    }

    var description: String {
        switch self {
        case .vision:
            return "Apple's built-in Vision framework (always available, fast)"
        case .ollama:
            return "Local Ollama server with vision models (requires setup, more accurate)"
        }
    }

    // MARK: - Capabilities

    var isAlwaysAvailable: Bool {
        self == .vision
    }

    var requiresExternalSetup: Bool {
        self == .ollama
    }

    var estimatedSpeed: String {
        switch self {
        case .vision: return "~3 seconds per page"
        case .ollama: return "~30 seconds per page"
        }
    }

    // MARK: - File Paths

    /// Directory name for storing OCR results
    var directoryName: String {
        switch self {
        case .vision: return "vision"
        case .ollama: return "ollama"
        }
    }
}
