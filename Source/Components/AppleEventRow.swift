//
//  AppleEventRow.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import SwiftUI

/// A row view for displaying an Apple Event rule (source -> destination)
struct AppleEventRow: View {
    @Bindable var rule: AppleEventRule

    var body: some View {
        HStack(spacing: 12) {
            // Destination executable info
            ExecutableIcon(iconPath: rule.destination.iconPath)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.destination.displayName)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(rule.destination.identifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Permission picker
            Picker("", selection: $rule.valueString) {
                Text(TCCProfileDisplayValue.allow.rawValue)
                    .tag(TCCProfileDisplayValue.allow.rawValue)
                Text(TCCProfileDisplayValue.deny.rawValue)
                    .tag(TCCProfileDisplayValue.deny.rawValue)
            }
            .labelsHidden()
            .frame(width: 100)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let source = Executable(identifier: "com.example.app", codeRequirement: "anchor apple")
    let destination = Executable(identifier: "com.apple.systemevents", codeRequirement: "anchor apple")
    destination.displayName = "System Events"
    destination.iconPath = IconFilePath.application

    return AppleEventRow(rule: AppleEventRule(source: source, destination: destination, value: true))
        .padding()
        .frame(width: 400)
}
