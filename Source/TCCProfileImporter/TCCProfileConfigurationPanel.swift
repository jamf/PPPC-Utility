//
//  TCCProfileViewController.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2018 Jamf Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

class TCCProfileConfigurationPanel {
    /// Load TCC Profile data from file
    ///
    /// - Parameters:
    ///   - importer: The TCCProfileImporter to use
    ///   - window: The window to present the open panel in
    /// - Returns: The decoded TCCProfile, or nil if the user cancelled
    func loadTCCProfileFromFile(importer: TCCProfileImporter, window: NSWindow) async throws -> TCCProfile? {
        let openPanel = NSOpenPanel()
        var contentTypes: [UTType] = [.propertyList]
        if let mobileconfigType = UTType(filenameExtension: "mobileconfig") {
            contentTypes.append(mobileconfigType)
        }
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Open TCCProfile File"

        let response = await openPanel.beginSheetModal(for: window)
        guard response == .OK else { return nil }

        guard let fileUrl = openPanel.url else {
            throw TCCProfileImportError.unableToOpenFile
        }

        return try importer.decodeTCCProfile(fileUrl: fileUrl)
    }
}
