//
//  TranscriptionMetadata.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation
import SwiftProjectKit

/// Custom metadata for transcription projects
/// Conforms to ProjectMetadata protocol from SwiftProjectKit
struct TranscriptionMetadata: ProjectMetadata, Codable {
    // MARK: - Required by ProjectMetadata
    var id: UUID
    var title: String
    var author: String
    var created: Date
    var modified: Date

    // MARK: - Custom Fields
    var publicationDate: String?
    var notes: String?
    var totalPages: Int?
    var sourceType: SourceType?
    var preprocessed: Bool?
    var ocrEngine: String?
    var llmEnhanced: Bool?

    // MARK: - Source Type
    enum SourceType: String, Codable {
        case pdf = "PDF"
        case images = "Images"

        var displayName: String {
            rawValue
        }
    }

    // MARK: - Initialization
    init(id: UUID = UUID(), title: String, author: String) {
        self.id = id
        self.title = title
        self.author = author
        self.created = Date()
        self.modified = Date()
    }

    // MARK: - Helper Methods
    mutating func markAsModified() {
        modified = Date()
    }

    var displayInfo: String {
        var info = "\(title) by \(author)"
        if let date = publicationDate {
            info += " (\(date))"
        }
        if let pages = totalPages {
            info += " - \(pages) pages"
        }
        return info
    }
}
