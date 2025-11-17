//
//  WorkflowStage.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation

/// Represents the workflow stages in the transcription process
enum WorkflowStage: String, Codable, CaseIterable, Identifiable {
    case setup
    case importing
    case preprocessing
    case ocr
    case editing
    case exporting

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .setup: return "Setup"
        case .importing: return "Import"
        case .preprocessing: return "Preprocess"
        case .ocr: return "OCR"
        case .editing: return "Edit"
        case .exporting: return "Export"
        }
    }

    var systemImage: String {
        switch self {
        case .setup: return "folder.badge.plus"
        case .importing: return "arrow.down.doc"
        case .preprocessing: return "wand.and.stars"
        case .ocr: return "doc.text.viewfinder"
        case .editing: return "square.and.pencil"
        case .exporting: return "square.and.arrow.up"
        }
    }

    var description: String {
        switch self {
        case .setup:
            return "Create a new project"
        case .importing:
            return "Import PDF or images"
        case .preprocessing:
            return "Enhance images for OCR (optional)"
        case .ocr:
            return "Extract text from images"
        case .editing:
            return "Review and edit transcription"
        case .exporting:
            return "Export final document"
        }
    }

    var isOptional: Bool {
        self == .preprocessing
    }

    // MARK: - Navigation

    var next: WorkflowStage? {
        switch self {
        case .setup: return .importing
        case .importing: return .preprocessing
        case .preprocessing: return .ocr
        case .ocr: return .editing
        case .editing: return .exporting
        case .exporting: return nil
        }
    }

    var previous: WorkflowStage? {
        switch self {
        case .setup: return nil
        case .importing: return .setup
        case .preprocessing: return .importing
        case .ocr: return .preprocessing
        case .editing: return .ocr
        case .exporting: return .editing
        }
    }

    func canTransitionTo(_ stage: WorkflowStage) -> Bool {
        // Can always go back
        if stage.rawValue < self.rawValue {
            return true
        }
        // Can skip optional stages
        if stage == next || (next?.isOptional == true && stage == next?.next) {
            return true
        }
        return false
    }
}
