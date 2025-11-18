//
//  MainWorkflowView.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI

struct MainWorkflowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Main three-panel layout
            HStack(spacing: 0) {
                // Left: Workflow Sidebar
                WorkflowSidebar()
                    .frame(width: 150)

                Divider()

                // Center: Document Viewer (always visible)
                DocumentViewerPanel()
                    .frame(minWidth: 400)

                Divider()

                // Right: Stage-specific content
                StageContentPanel()
                    .frame(minWidth: 300, idealWidth: 400, maxWidth: 600)
            }

            Divider()

            // Bottom: Status Bar
            StatusBarView()
                .frame(height: 60)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let project = appState.currentProject {
                    Text(project.metadata.title)
                        .font(.headline)
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    appState.showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
}
