//
//  StageContentPanel.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI

struct StageContentPanel: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(appState.currentStage.displayName)
                    .font(.headline)

                Spacer()

                if appState.currentStage.isOptional {
                    Text("Optional")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Stage-specific content
            ScrollView {
                Group {
                    switch appState.currentStage {
                    case .setup:
                        // Handled in main content view
                        EmptyView()

                    case .importing:
                        ImportStageView()

                    case .preprocessing:
                        PreprocessStageView()

                    case .ocr:
                        OCRStageView()

                    case .editing:
                        EditStageView()

                    case .exporting:
                        ExportStageView()
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct StatusBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            // Status message
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)

                Text(appState.statusMessage.isEmpty ? "Ready" : appState.statusMessage)
                    .font(.subheadline)

                Spacer()

                Text(appState.currentStageCompletion)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            if appState.progress > 0 {
                ProgressView(value: appState.progress)
                    .progressViewStyle(.linear)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}
