//
//  AlmanakApp.swift
//  Almanak2
//
//  Created by AI Assistant on 2025-11-17.
//

import SwiftUI

@main
struct AlmanakApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    // Load recent projects on launch
                    Task {
                        try? await appState.projectManager.loadRecentProjects()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project...") {
                    appState.reset()
                    appState.currentStage = .setup
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open Project...") {
                    appState.showingProjectList = true
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Save Project") {
                    Task {
                        try? await appState.saveProject()
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(appState.currentProject == nil)
            }

            CommandGroup(replacing: .help) {
                Button("Almanak2 Help") {
                    if let url = URL(string: "https://github.com/jeffcwolf/Almanak2") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.currentProject == nil && appState.currentStage == .setup {
                ProjectListOrCreationView()
            } else {
                MainWorkflowView()
            }
        }
        .alert(item: $appState.errorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                primaryButton: .default(Text("OK")),
                secondaryButton: alert.retryAction != nil
                    ? .default(Text("Retry"), action: {
                        if let retry = alert.retryAction {
                            Task { await retry() }
                        }
                    })
                    : .cancel()
            )
        }
    }
}

struct ProjectListOrCreationView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingNewProject = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Almanak2")
                .font(.system(size: 48, weight: .bold))

            Text("OCR Transcription for Historical Documents")
                .font(.title3)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                Button {
                    showingNewProject = true
                } label: {
                    VStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 40))
                        Text("New Project")
                    }
                    .frame(width: 200, height: 150)
                }
                .buttonStyle(.bordered)

                Button {
                    appState.showingProjectList = true
                } label: {
                    VStack {
                        Image(systemName: "folder")
                            .font(.system(size: 40))
                        Text("Open Project")
                    }
                    .frame(width: 200, height: 150)
                }
                .buttonStyle(.bordered)
                .disabled(appState.projectManager.recentProjects.isEmpty)
            }

            if !appState.projectManager.recentProjects.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Projects")
                        .font(.headline)

                    ForEach(appState.projectManager.recentProjects.prefix(5), id: \.id) { project in
                        Button {
                            Task {
                                try? await appState.loadProject(id: project.id)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(project.metadata.title)
                                        .font(.headline)
                                    Text("by \(project.metadata.author)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(project.metadata.modified.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 600)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingNewProject) {
            ProjectCreationView()
        }
        .sheet(isPresented: $appState.showingProjectList) {
            ProjectListView()
        }
    }
}

struct ProjectCreationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var publicationDate = ""
    @State private var notes = ""
    @State private var isCreating = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Project")
                .font(.title)

            Form {
                TextField("Book Title", text: $title)
                TextField("Author", text: $author)
                TextField("Publication Date (optional)", text: $publicationDate)
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Create") {
                    Task {
                        isCreating = true
                        do {
                            try await appState.createProject(
                                title: title,
                                author: author,
                                publicationDate: publicationDate.isEmpty ? nil : publicationDate,
                                notes: notes.isEmpty ? nil : notes
                            )
                            dismiss()
                        } catch {
                            appState.handleError(error)
                        }
                        isCreating = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || author.isEmpty || isCreating)
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct ProjectListView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Text("Open Project")
                .font(.title)
                .padding()

            List(appState.projectManager.recentProjects, id: \.id) { project in
                Button {
                    Task {
                        try? await appState.loadProject(id: project.id)
                        dismiss()
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text(project.metadata.title)
                            .font(.headline)
                        Text("by \(project.metadata.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Modified: \(project.metadata.modified.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
}
