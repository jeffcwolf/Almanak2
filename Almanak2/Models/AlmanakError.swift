//
//  AlmanakError.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation

/// Comprehensive error types for the Almanak2 application
enum AlmanakError: LocalizedError {
    // MARK: - Project Errors
    case projectCreationFailed(String)
    case projectLoadFailed(UUID)
    case projectSaveFailed(String)
    case projectNotFound

    // MARK: - Import Errors
    case invalidPDF(String)
    case imageImportFailed(String)
    case unsupportedFormat(String)
    case pageExtractionFailed(Int)

    // MARK: - Preprocessing Errors
    case preprocessingFailed(Int, String)
    case imageConversionFailed
    case invalidImage

    // MARK: - OCR Errors
    case ocrFailed(Int, String)
    case engineUnavailable(String)
    case noOCRResult

    // MARK: - LLM Errors
    case llmUnavailable
    case enhancementFailed(String)
    case connectionFailed

    // MARK: - File Errors
    case fileNotFound(URL)
    case writePermissionDenied(URL)
    case readPermissionDenied(URL)
    case diskFull
    case directoryCreationFailed(URL)

    // MARK: - Workflow Errors
    case invalidStageTransition(from: WorkflowStage, to: WorkflowStage)
    case noProjectLoaded
    case noPageSelected

    // MARK: - LocalizedError Conformance

    var errorDescription: String? {
        switch self {
        case .projectCreationFailed(let reason):
            return "Could not create project: \(reason)"
        case .projectLoadFailed(let id):
            return "Could not load project with ID: \(id)"
        case .projectSaveFailed(let reason):
            return "Could not save project: \(reason)"
        case .projectNotFound:
            return "Project not found"

        case .invalidPDF(let reason):
            return "Invalid PDF file: \(reason)"
        case .imageImportFailed(let reason):
            return "Could not import images: \(reason)"
        case .unsupportedFormat(let format):
            return "Unsupported file format: \(format)"
        case .pageExtractionFailed(let page):
            return "Could not extract page \(page + 1)"

        case .preprocessingFailed(let page, let reason):
            return "Preprocessing failed on page \(page + 1): \(reason)"
        case .imageConversionFailed:
            return "Could not convert image to required format"
        case .invalidImage:
            return "Invalid image data"

        case .ocrFailed(let page, let reason):
            return "OCR failed on page \(page + 1): \(reason)"
        case .engineUnavailable(let engine):
            return "\(engine) engine is not available"
        case .noOCRResult:
            return "No OCR result available"

        case .llmUnavailable:
            return "LLM service is not available"
        case .enhancementFailed(let reason):
            return "Text enhancement failed: \(reason)"
        case .connectionFailed:
            return "Could not connect to server"

        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .writePermissionDenied(let url):
            return "Write permission denied for: \(url.lastPathComponent)"
        case .readPermissionDenied(let url):
            return "Read permission denied for: \(url.lastPathComponent)"
        case .diskFull:
            return "Disk is full. Please free up space and try again."
        case .directoryCreationFailed(let url):
            return "Could not create directory: \(url.lastPathComponent)"

        case .invalidStageTransition(let from, let to):
            return "Cannot transition from \(from.displayName) to \(to.displayName)"
        case .noProjectLoaded:
            return "No project is currently loaded"
        case .noPageSelected:
            return "No page is currently selected"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .projectCreationFailed, .projectSaveFailed:
            return "Check disk space and file permissions."
        case .projectLoadFailed:
            return "The project may be corrupted. Try creating a new project."

        case .invalidPDF:
            return "Try opening the PDF in Preview to verify it's valid."
        case .unsupportedFormat:
            return "Supported formats: PDF, JP2, PNG, JPEG, TIFF, GIF, BMP, WebP, HEIC"
        case .imageImportFailed:
            return "Ensure images are valid and accessible."

        case .preprocessingFailed:
            return "Try skipping preprocessing or using different options."

        case .ocrFailed:
            return "Try using a different OCR engine or preprocessing the image first."
        case .engineUnavailable(let engine):
            if engine.contains("Ollama") {
                return "Install and start Ollama server, or use Apple Vision instead."
            }
            return "Try using a different OCR engine."

        case .llmUnavailable:
            return "Install and start Ollama server, or skip LLM enhancement."
        case .enhancementFailed:
            return "Try using the raw OCR text without enhancement."

        case .writePermissionDenied, .readPermissionDenied:
            return "Check file permissions in System Settings > Privacy & Security."
        case .diskFull:
            return "Free up at least 1GB of disk space."

        case .noProjectLoaded:
            return "Create or open a project first."
        case .noPageSelected:
            return "Select a page to process."

        default:
            return nil
        }
    }

    var failureReason: String? {
        switch self {
        case .projectCreationFailed(let reason),
             .projectSaveFailed(let reason),
             .invalidPDF(let reason),
             .imageImportFailed(let reason),
             .preprocessingFailed(_, let reason),
             .ocrFailed(_, let reason),
             .enhancementFailed(let reason):
            return reason

        case .diskFull:
            return "Insufficient disk space"

        case .engineUnavailable(let engine):
            return "\(engine) is not running or not installed"

        default:
            return nil
        }
    }
}

// MARK: - Error Alert Helper

struct ErrorAlert: Identifiable {
    let id = UUID()
    let error: Error
    let retryAction: (() async -> Void)?

    var title: String {
        if let almanakError = error as? AlmanakError {
            return "Error"
        }
        return "Unexpected Error"
    }

    var message: String {
        error.localizedDescription
    }

    var suggestion: String? {
        (error as? AlmanakError)?.recoverySuggestion
    }
}
