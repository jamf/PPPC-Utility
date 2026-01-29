//
//  AppCommands.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import SwiftUI

// MARK: - Focused Values for Menu Actions

struct AppActionsKey: FocusedValueKey {
    typealias Value = AppActions
}

extension FocusedValues {
    var appActions: AppActions? {
        get { self[AppActionsKey.self] }
        set { self[AppActionsKey.self] = newValue }
    }
}

/// Container for actions that can be triggered from menus
@Observable
final class AppActions {
    var addExecutable: () -> Void = {}
    var removeExecutable: () -> Void = {}
    var importProfile: () -> Void = {}
    var saveProfile: () -> Void = {}
    var uploadProfile: () -> Void = {}
    var newProfile: () -> Void = {}

    var canRemove: Bool = false
    var canSave: Bool = false
}

// MARK: - App Commands

struct PPPCCommands: Commands {
    @FocusedValue(\.appActions) var actions

    var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("New Profile") {
                actions?.newProfile()
            }
            .keyboardShortcut("n", modifiers: .command)

            Divider()

            Button("Add Application...") {
                actions?.addExecutable()
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Import Profile...") {
                actions?.importProfile()
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])

            Divider()

            Button("Save Profile...") {
                actions?.saveProfile()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(!(actions?.canSave ?? false))

            Button("Upload to Jamf Pro...") {
                actions?.uploadProfile()
            }
            .keyboardShortcut("u", modifiers: [.command, .shift])
            .disabled(!(actions?.canSave ?? false))
        }

        // Edit Menu additions
        CommandGroup(after: .pasteboard) {
            Divider()

            Button("Remove Selected") {
                actions?.removeExecutable()
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(!(actions?.canRemove ?? false))
        }
    }
}
