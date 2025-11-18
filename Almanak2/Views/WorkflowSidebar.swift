//
//  WorkflowSidebar.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI

struct WorkflowSidebar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            Text("Workflow")
                .font(.headline)
                .padding()

            List(WorkflowStage.allCases, id: \.self) { stage in
                StageButton(stage: stage)
            }
            .listStyle(.sidebar)

            Spacer()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct StageButton: View {
    @EnvironmentObject var appState: AppState
    let stage: WorkflowStage

    private var isComplete: Bool {
        switch stage {
        case .setup:
            return appState.currentProject != nil
        case .importing:
            return appState.totalPages > 0
        case .preprocessing:
            return true // Optional stage
        case .ocr:
            guard let project = appState.currentProject else { return false }
            return appState.ocrManager.ocrPageCount(for: .vision, projectURL: project.url) > 0
        case .editing:
            guard let project = appState.currentProject else { return false }
            return appState.llmManager.transcriptionCount(projectURL: project.url) > 0
        case .exporting:
            guard let project = appState.currentProject else { return false }
            return appState.llmManager.transcriptionCount(projectURL: project.url) == appState.totalPages
        }
    }

    private var isActive: Bool {
        appState.currentStage == stage
    }

    var body: some View {
        Button {
            appState.goToStage(stage)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)

                    if isComplete {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    } else {
                        Image(systemName: stage.systemImage)
                            .foregroundColor(isActive ? .white : .secondary)
                            .font(.system(size: 14))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(stage.displayName)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular))

                    if stage.isOptional {
                        Text("Optional")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(!appState.currentStage.canTransitionTo(stage))
    }
}
