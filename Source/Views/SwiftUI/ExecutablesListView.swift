//
//  ExecutablesListView.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import SwiftUI
import UniformTypeIdentifiers

/// Sidebar view showing the list of executables in the profile
struct ExecutablesListView: View {
    @Bindable var model: Model
    @Binding var selection: Executable?

    var body: some View {
        List(selection: $selection) {
            ForEach(model.selectedExecutables) { executable in
                ExecutableRow(executable: executable)
                    .tag(executable)
            }
            .onDelete(perform: deleteExecutables)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 250)
        .dropDestination(for: URL.self) { urls, _ in
            addExecutables(from: urls)
            return !urls.isEmpty
        }
        .contextMenu {
            Button("Add Application...") {
                promptForExecutables()
            }
        }
    }

    private func deleteExecutables(at offsets: IndexSet) {
        model.selectedExecutables.remove(atOffsets: offsets)
        if let first = model.selectedExecutables.first {
            selection = first
        } else {
            selection = nil
        }
    }

    private func addExecutables(from urls: [URL]) {
        for url in urls {
            model.loadExecutable(url: url) { result in
                if case .success(let executable) = result {
                    if !model.selectedExecutables.contains(executable) {
                        model.selectedExecutables.append(executable)
                        if selection == nil {
                            selection = executable
                        }
                    }
                }
            }
        }
    }

    private func promptForExecutables() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application, .unixExecutable, .bundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)

        if panel.runModal() == .OK {
            addExecutables(from: panel.urls)
        }
    }
}

#Preview {
    ExecutablesListView(
        model: Model.shared,
        selection: .constant(nil)
    )
}
