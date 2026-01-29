//
//  ContentView.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import OSLog
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var model = Model.shared
    @State private var selectedExecutable: Executable?
    @State private var showingSaveSheet = false
    @State private var showingUploadSheet = false
    @State private var signingIdentities: [SigningIdentity] = []
    @State private var appActions = AppActions()

    private let logger = Logger.TCCProfileViewController

    var body: some View {
        NavigationSplitView {
            ExecutablesListView(model: model, selection: $selectedExecutable)
                .navigationSplitViewColumnWidth(min: 220, ideal: 280)
        } detail: {
            if let executable = selectedExecutable {
                PolicyDetailView(executable: executable, model: model)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("PPPC Utility")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveProfileView(model: model)
        }
        .sheet(isPresented: $showingUploadSheet) {
            UploadInfoView(signingIdentities: signingIdentities) {
                showingUploadSheet = false
            }
        }
        .focusedSceneValue(\.appActions, appActions)
        .onAppear {
            loadSigningIdentities()
            setupAppActions()
        }
        .onChange(of: selectedExecutable) { _, _ in
            updateActionStates()
        }
        .onChange(of: model.selectedExecutables.count) { _, _ in
            updateActionStates()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.app")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Application Selected")
                .font(.title2)

            Text("Add an application using the + button\nor drag and drop from Finder")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Application...") {
                promptForExecutables()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                promptForExecutables()
            } label: {
                Label("Add", systemImage: "plus")
            }
            .help("Add application to profile")

            Button {
                removeSelectedExecutable()
            } label: {
                Label("Remove", systemImage: "minus")
            }
            .help("Remove selected application")
            .disabled(selectedExecutable == nil)
        }

        ToolbarItemGroup(placement: .secondaryAction) {
            Button {
                importProfile()
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .help("Import existing profile")

            Divider()

            Toggle(isOn: Binding(
                get: { !model.usingLegacyAllowKey },
                set: { model.usingLegacyAllowKey = !$0 }
            )) {
                Label("Big Sur+", systemImage: "laptopcomputer")
            }
            .help("Enable Big Sur compatibility (macOS 11+)")
        }

        ToolbarItemGroup(placement: .confirmationAction) {
            Button {
                showingSaveSheet = true
            } label: {
                Label("Save", systemImage: "square.and.arrow.down.on.square")
            }
            .help("Save profile to disk")
            .disabled(model.selectedExecutables.isEmpty)

            Button {
                showingUploadSheet = true
            } label: {
                Label("Upload", systemImage: "icloud.and.arrow.up")
            }
            .help("Upload to Jamf Pro")
            .disabled(model.selectedExecutables.isEmpty)
        }
    }

    // MARK: - Actions

    private func promptForExecutables() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application, .unixExecutable, .bundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)

        if panel.runModal() == .OK {
            for url in panel.urls {
                model.loadExecutable(url: url) { result in
                    if case .success(let executable) = result {
                        if !model.selectedExecutables.contains(executable) {
                            model.selectedExecutables.append(executable)
                            if selectedExecutable == nil {
                                selectedExecutable = executable
                            }
                        }
                    }
                }
            }
        }
    }

    private func removeSelectedExecutable() {
        guard let selected = selectedExecutable,
              let index = model.selectedExecutables.firstIndex(of: selected) else { return }

        model.selectedExecutables.remove(at: index)

        if model.selectedExecutables.isEmpty {
            selectedExecutable = nil
        } else if index < model.selectedExecutables.count {
            selectedExecutable = model.selectedExecutables[index]
        } else {
            selectedExecutable = model.selectedExecutables.last
        }
    }

    private func importProfile() {
        let tccProfileImporter = TCCProfileImporter()
        let tccConfigPanel = TCCProfileConfigurationPanel()

        guard let window = NSApp.keyWindow else { return }

        tccConfigPanel.loadTCCProfileFromFile(importer: tccProfileImporter, window: window) { result in
            switch result {
            case .success(let tccProfile):
                model.importProfile(tccProfile: tccProfile)
                if model.requiresAuthorizationKey() {
                    model.usingLegacyAllowKey = false
                }
                selectedExecutable = model.selectedExecutables.first
            case .failure(let error):
                if !error.isCancelled {
                    logger.error("Import failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadSigningIdentities() {
        do {
            signingIdentities = try SecurityWrapper.loadSigningIdentities()
        } catch {
            logger.error("Error loading identities: \(error.localizedDescription)")
        }
    }

    private func setupAppActions() {
        appActions.addExecutable = { [self] in promptForExecutables() }
        appActions.removeExecutable = { [self] in removeSelectedExecutable() }
        appActions.importProfile = { [self] in importProfile() }
        appActions.saveProfile = { [self] in showingSaveSheet = true }
        appActions.uploadProfile = { [self] in showingUploadSheet = true }
        appActions.newProfile = { [self] in newProfile() }
        updateActionStates()
    }

    private func updateActionStates() {
        appActions.canRemove = selectedExecutable != nil
        appActions.canSave = !model.selectedExecutables.isEmpty
    }

    private func newProfile() {
        model.selectedExecutables.removeAll()
        model.importedTCCProfile = nil
        model.usingLegacyAllowKey = true
        selectedExecutable = nil
    }
}

#Preview {
    ContentView()
}
