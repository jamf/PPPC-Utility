//
//  TCCProfileCongurationPanel.swift
//  PPPC Utility
//
//  Created by Mike Anderson on 2/19/20.
//  Copyright © 2020 Jamf. All rights reserved.
//

import Foundation
import AppKit

class TCCProfileConfigurationPanel {
    /// Load TCC Profile data from file
     ///
     /// - Parameter completion: TCCProfileImportCompletion - success with TCCProfile or failure with TCCProfileImport Error
    func loadTCCProfileFromFile(importer: TCCProfileImporter, window: NSWindow, _ completion: @escaping TCCProfileImportCompletion) {
         let openPanel = NSOpenPanel.init()
         openPanel.allowedFileTypes = ["mobileconfig", "plist"]
         openPanel.allowsMultipleSelection = false
         openPanel.canChooseDirectories = false
         openPanel.canCreateDirectories = false
         openPanel.canChooseFiles = true
         openPanel.title = "Open TCCProfile File"

         openPanel.beginSheetModal(for: window) { (response) in
             if response != .OK {
                 // Cancelled
                 completion(TCCProfileImportResult.failure(nil))
             } else {
                 if let result = openPanel.url {
                     importer.decodeTCCProfile(fileUrl: result, { tccProfileResult in
                         return completion(tccProfileResult)
                     })
                 } else {
                     completion(TCCProfileImportResult.failure(TCCProfileImportError.unableToOpenFile))
                 }
             }
         }

     }
}
