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
                completion(.failure(.cancelled))
             } else {
                 if let result = openPanel.url {
                     importer.decodeTCCProfile(fileUrl: result) { tccProfileResult in
                         return completion(tccProfileResult)
                     }
                 } else {
                     completion(.failure(TCCProfileImportError.unableToOpenFile))
                 }
             }
         }

     }
}
