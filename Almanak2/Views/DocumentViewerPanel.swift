//
//  DocumentViewerPanel.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI

struct DocumentViewerPanel: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Document Viewer")
                    .font(.headline)

                Spacer()

                if appState.totalPages > 0 {
                    Text("Page \((appState.selectedPage ?? 0) + 1) / \(appState.totalPages)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Image view
            ZStack {
                if let image = appState.documentManager.currentPageImage {
                    ScrollView([.horizontal, .vertical]) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("No page loaded")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        if appState.currentStage == .importing {
                            Text("Import a document to begin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))

            Divider()

            // Navigation bar
            if appState.totalPages > 0 {
                PageNavigator()
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
            }
        }
    }
}

struct PageNavigator: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Button {
                Task {
                    await appState.previousPage()
                }
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .disabled(!(appState.selectedPage ?? 0 > 0))

            Spacer()

            HStack(spacing: 4) {
                Text("Go to page:")
                    .font(.caption)

                TextField("", value: Binding(
                    get: { (appState.selectedPage ?? 0) + 1 },
                    set: { newValue in
                        Task {
                            await appState.goToPage(newValue - 1)
                        }
                    }
                ), format: .number)
                .frame(width: 50)
                .textFieldStyle(.roundedBorder)
            }

            Spacer()

            Button {
                Task {
                    await appState.nextPage()
                }
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
            .disabled(!(appState.selectedPage ?? 0) < appState.totalPages - 1)
        }
    }
}
