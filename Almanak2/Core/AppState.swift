//
//  AppState.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import Foundation
import SwiftUI
import SwiftProjectKit

/// Central coordinator for the Almanak2 application
/// Manages workflow orchestration and state across all stages
@MainActor
class AppState: ObservableObject {
    // MARK: - Managers (Wrap Foundation Packages)

    let projectManager: ProjectManager
    let documentManager: DocumentManager
    let preprocessingManager: PreprocessingManager
    let ocrManager: OCRManager
    let llmManager: LLMManager

    // MARK: - Current State

    @Published var currentProject: Project<TranscriptionMetadata, WorkflowStage>?
    @Published var currentStage: WorkflowStage = .setup
    @Published var selectedPage: Int?

    // MARK: - Progress Tracking

    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var totalPages: Int = 0
    @Published var processedPages: Int = 0

    // MARK: - Page Data

    @Published var pages: [PageData] = []

    // MARK: - UI State

    @Published var errorAlert: ErrorAlert?
    @Published var showingSettings = false
    @Published var showingProjectList = false

    // MARK: - Initialization

    init() {
        self.projectManager = ProjectManager()
        self.documentManager = DocumentManager()
        self.preprocessingManager = PreprocessingManager()
        self.ocrManager = OCRManager()
        self.llmManager = LLMManager()

        // Observe project changes
        setupObservers()
    }

    private func setupObservers() {
        // Sync current project from project manager
        projectManager.$currentProject
            .assign(to: &$currentProject)

        // Update total pages when document is imported
        documentManager.$totalPages
            .sink { [weak self] total in
                self?.totalPages = total
                self?.initializePages(count: total)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Project Lifecycle

    /// Create a new project
    func createProject(title: String, author: String, publicationDate: String?, notes: String?) async throws {
        do {
            try await projectManager.createProject(
                title: title,
                author: author,
                publicationDate: publicationDate,
                notes: notes
            )

            currentStage = .importing
            updateStatus("Project created successfully")
        } catch {
            handleError(error)
            throw error
        }
    }

    /// Load an existing project
    func loadProject(id: UUID) async throws {
        do {
            try await projectManager.loadProject(id: id)

            // Restore workflow state
            await restoreWorkflowState()

            updateStatus("Project loaded successfully")
        } catch {
            handleError(error)
            throw error
        }
    }

    /// Save current project
    func saveProject() async throws {
        try await projectManager.saveProject()
    }

    // MARK: - Workflow Navigation

    /// Advance to the next workflow stage
    func advanceStage() {
        guard let next = currentStage.next else { return }
        currentStage = next
        updateStatus("Moved to \(next.displayName) stage")
    }

    /// Go back to previous stage
    func goBackStage() {
        guard let previous = currentStage.previous else { return }
        currentStage = previous
        updateStatus("Returned to \(previous.displayName) stage")
    }

    /// Jump to a specific stage
    func goToStage(_ stage: WorkflowStage) {
        guard currentStage.canTransitionTo(stage) else {
            handleError(AlmanakError.invalidStageTransition(from: currentStage, to: stage))
            return
        }

        currentStage = stage
        updateStatus("Jumped to \(stage.displayName) stage")
    }

    // MARK: - Page Navigation

    /// Go to a specific page
    func goToPage(_ index: Int) async {
        guard let project = currentProject else { return }
        guard index >= 0 && index < totalPages else { return }

        selectedPage = index

        do {
            try await documentManager.loadPage(index, projectURL: project.url)
            updateStatus("Viewing page \(index + 1) of \(totalPages)")
        } catch {
            handleError(error)
        }
    }

    /// Go to next page
    func nextPage() async {
        guard let current = selectedPage else {
            await goToPage(0)
            return
        }

        if current < totalPages - 1 {
            await goToPage(current + 1)
        }
    }

    /// Go to previous page
    func previousPage() async {
        guard let current = selectedPage, current > 0 else { return }
        await goToPage(current - 1)
    }

    // MARK: - Page Management

    private func initializePages(count: Int) {
        pages = (0..<count).map { PageData(index: $0) }
    }

    func updatePageData(at index: Int, update: (inout PageData) -> Void) {
        guard index >= 0 && index < pages.count else { return }
        update(&pages[index])
    }

    func getPageData(at index: Int) -> PageData? {
        guard index >= 0 && index < pages.count else { return nil }
        return pages[index]
    }

    // MARK: - Progress Tracking

    /// Update progress and status message
    func updateProgress(_ current: Int, _ total: Int, message: String) {
        processedPages = current
        totalPages = total
        progress = total > 0 ? Double(current) / Double(total) : 0
        statusMessage = message
    }

    /// Update status message only
    func updateStatus(_ message: String) {
        statusMessage = message
    }

    /// Calculate overall completion percentage
    var completionPercentage: Double {
        guard !pages.isEmpty else { return 0 }

        let totalProgress = pages.reduce(0.0) { $0 + $1.completionProgress }
        return totalProgress / Double(pages.count)
    }

    /// Get completion status for current stage
    var currentStageCompletion: String {
        switch currentStage {
        case .setup:
            return currentProject != nil ? "Complete" : "Not started"
        case .importing:
            return totalPages > 0 ? "\(totalPages) pages imported" : "Not started"
        case .preprocessing:
            let preprocessed = preprocessingManager.preprocessedPageCount(projectURL: currentProject!.url)
            return "\(preprocessed) / \(totalPages) pages"
        case .ocr:
            let visionCount = ocrManager.ocrPageCount(for: .vision, projectURL: currentProject!.url)
            return "\(visionCount) / \(totalPages) pages"
        case .editing:
            let transcribed = llmManager.transcriptionCount(projectURL: currentProject!.url)
            return "\(transcribed) / \(totalPages) pages"
        case .exporting:
            return llmManager.transcriptionCount(projectURL: currentProject!.url) == totalPages ? "Ready" : "Not ready"
        }
    }

    // MARK: - Workflow State Persistence

    /// Save current workflow state
    func saveWorkflowState() async throws {
        guard let project = currentProject else { return }

        let stateData: [String: Any] = [
            "currentStage": currentStage.rawValue,
            "selectedPage": selectedPage ?? 0,
            "totalPages": totalPages,
            "processedPages": processedPages,
            "timestamp": Date().timeIntervalSince1970
        ]

        let stateURL = project.url
            .appendingPathComponent(".swiftproject")
            .appendingPathComponent("workflow_state.json")

        let jsonData = try JSONSerialization.data(withJSONObject: stateData, options: .prettyPrinted)
        try jsonData.write(to: stateURL)
    }

    /// Restore workflow state from saved data
    private func restoreWorkflowState() async {
        guard let project = currentProject else { return }

        let stateURL = project.url
            .appendingPathComponent(".swiftproject")
            .appendingPathComponent("workflow_state.json")

        guard FileManager.default.fileExists(atPath: stateURL.path),
              let jsonData = try? Data(contentsOf: stateURL),
              let stateData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }

        // Restore stage
        if let stageString = stateData["currentStage"] as? String,
           let stage = WorkflowStage(rawValue: stageString) {
            currentStage = stage
        }

        // Restore page selection
        if let page = stateData["selectedPage"] as? Int {
            await goToPage(page)
        }

        // Restore counts
        if let total = stateData["totalPages"] as? Int {
            totalPages = total
        }

        if let processed = stateData["processedPages"] as? Int {
            processedPages = processed
        }
    }

    // MARK: - Error Handling

    func handleError(_ error: Error) {
        let almanakError = error as? AlmanakError
        errorAlert = ErrorAlert(error: error, retryAction: nil)
        statusMessage = error.localizedDescription
    }

    func handleError(_ error: Error, retryAction: @escaping () async -> Void) {
        errorAlert = ErrorAlert(error: error, retryAction: retryAction)
        statusMessage = error.localizedDescription
    }

    // MARK: - Utilities

    /// Check if can proceed to next stage
    var canAdvanceStage: Bool {
        switch currentStage {
        case .setup:
            return currentProject != nil
        case .importing:
            return totalPages > 0
        case .preprocessing:
            return true // Optional stage
        case .ocr:
            let hasOCR = ocrManager.ocrPageCount(for: .vision, projectURL: currentProject!.url) > 0
            return hasOCR
        case .editing:
            return llmManager.transcriptionCount(projectURL: currentProject!.url) > 0
        case .exporting:
            return false // Last stage
        }
    }

    /// Reset all state (for new project)
    func reset() {
        currentProject = nil
        currentStage = .setup
        selectedPage = nil
        progress = 0.0
        statusMessage = ""
        totalPages = 0
        processedPages = 0
        pages = []

        documentManager.reset()
        preprocessingManager.reset()
        ocrManager.reset()
        llmManager.reset()
    }
}

// MARK: - Combine Support
import Combine
