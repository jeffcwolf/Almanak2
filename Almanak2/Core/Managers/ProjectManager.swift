//
//  ProjectManager.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation
import SwiftProjectKit

/// Manages project lifecycle using SwiftProjectKit
@MainActor
class ProjectManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentProject: Project<TranscriptionMetadata, WorkflowStage>?
    @Published var recentProjects: [Project<TranscriptionMetadata, WorkflowStage>] = []
    @Published var isLoading = false

    // MARK: - Private Properties
    private let store: ProjectStore

    // MARK: - Initialization
    init() {
        self.store = ProjectStore(appName: "Almanak2")
    }

    // MARK: - Project Creation

    /// Create a new transcription project
    func createProject(
        title: String,
        author: String,
        publicationDate: String? = nil,
        notes: String? = nil
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        // Create project with custom metadata
        currentProject = try await store.create(title: title, author: author) { metadata in
            metadata.publicationDate = publicationDate
            metadata.notes = notes
            metadata.totalPages = 0
            metadata.sourceType = nil
            metadata.preprocessed = false
            metadata.ocrEngine = nil
            metadata.llmEnhanced = false
        }

        guard let project = currentProject else {
            throw AlmanakError.projectCreationFailed("Project creation returned nil")
        }

        // Create directory structure
        try createProjectDirectories(at: project.url)

        // Refresh recent projects list
        try await loadRecentProjects()
    }

    // MARK: - Project Loading

    /// Load recent projects
    func loadRecentProjects() async throws {
        isLoading = true
        defer { isLoading = false }

        recentProjects = try await store.list()
    }

    /// Load a specific project by ID
    func loadProject(id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let project = try await store.load(id: id) else {
            throw AlmanakError.projectLoadFailed(id)
        }

        currentProject = project
    }

    /// Load a project by URL
    func loadProject(url: URL) async throws {
        isLoading = true
        defer { isLoading = false }

        // Extract UUID from URL path
        let projectID = url.lastPathComponent
        guard let uuid = UUID(uuidString: projectID) else {
            throw AlmanakError.projectLoadFailed(UUID())
        }

        try await loadProject(id: uuid)
    }

    // MARK: - Project Saving

    /// Save current project
    func saveProject() async throws {
        guard var project = currentProject else {
            throw AlmanakError.noProjectLoaded
        }

        // Update modified date
        project.metadata.markAsModified()
        currentProject = project

        try await store.save(project)
    }

    /// Update project metadata
    func updateMetadata(_ update: (inout TranscriptionMetadata) -> Void) async throws {
        guard var project = currentProject else {
            throw AlmanakError.noProjectLoaded
        }

        update(&project.metadata)
        currentProject = project

        try await saveProject()
    }

    // MARK: - Project Deletion

    /// Delete a project
    func deleteProject(id: UUID) async throws {
        try await store.delete(id: id)

        // If this was the current project, clear it
        if currentProject?.id == id {
            currentProject = nil
        }

        // Refresh recent projects
        try await loadRecentProjects()
    }

    // MARK: - Directory Management

    /// Create the standard directory structure for a project
    private func createProjectDirectories(at projectURL: URL) throws {
        let fileManager = FileManager.default
        let directories = [
            "source",
            "pages",
            "preprocessed",
            "ocr/vision",
            "ocr/ollama",
            "transcription"
        ]

        for directory in directories {
            let dirURL = projectURL.appendingPathComponent(directory)
            do {
                try fileManager.createDirectory(
                    at: dirURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw AlmanakError.directoryCreationFailed(dirURL)
            }
        }
    }

    /// Get directory URL for a specific purpose
    func directoryURL(for type: DirectoryType) -> URL? {
        guard let project = currentProject else { return nil }

        switch type {
        case .source:
            return project.url.appendingPathComponent("source")
        case .pages:
            return project.url.appendingPathComponent("pages")
        case .preprocessed:
            return project.url.appendingPathComponent("preprocessed")
        case .ocr(let engine):
            return project.url
                .appendingPathComponent("ocr")
                .appendingPathComponent(engine.directoryName)
        case .transcription:
            return project.url.appendingPathComponent("transcription")
        }
    }

    // MARK: - Helper Methods

    /// Check if a project is currently loaded
    var hasProject: Bool {
        currentProject != nil
    }

    /// Get current project URL
    var projectURL: URL? {
        currentProject?.url
    }

    /// Get current project title
    var projectTitle: String? {
        currentProject?.metadata.title
    }

    // MARK: - Directory Types

    enum DirectoryType {
        case source
        case pages
        case preprocessed
        case ocr(OCREngineType)
        case transcription
    }
}
