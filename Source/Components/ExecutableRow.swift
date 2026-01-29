//
//  ExecutableRow.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import SwiftUI

/// A row view displaying an executable's icon, name, and identifier
struct ExecutableRow: View {
    let executable: Executable

    var body: some View {
        HStack(spacing: 8) {
            ExecutableIcon(iconPath: executable.iconPath)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(executable.displayName)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(executable.identifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Displays an icon from a file path
struct ExecutableIcon: View {
    let iconPath: String

    var body: some View {
        if let nsImage = NSImage(contentsOfFile: iconPath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        ExecutableRow(executable: {
            let exe = Executable(identifier: "com.apple.Safari", codeRequirement: "anchor apple")
            exe.displayName = "Safari"
            exe.iconPath = "/Applications/Safari.app/Contents/Resources/AppIcon.icns"
            return exe
        }())

        ExecutableRow(executable: {
            let exe = Executable(identifier: "/usr/bin/python3", codeRequirement: "anchor apple")
            exe.displayName = "python3"
            exe.iconPath = IconFilePath.binary
            return exe
        }())
    }
    .padding()
}
