//
//  TCCProfileImporter.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2019 Jamf Software
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

import Foundation
import AppKit

enum TCCProfileImportResult {
    case success(TCCProfile)
    case failure(TCCProfileImportError?)
}

typealias TCCProfileImportCompletion = ((TCCProfileImportResult) -> Void)


/// Load tcc profiles
public class TCCProfileImporter {

    // MARK: Load TCCProfile

    /// Load TCC Profile data from file
    ///
    /// - Parameter completion: TCCProfileImportCompletion - success with TCCProfile or failure with TCCProfileImport Error
    func loadTCCProfileFromFile(window: NSWindow, _ completion: @escaping TCCProfileImportCompletion) {
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
                    self.decodeTCCProfile(fileUrl: result, { tccProfileResult in
                        return completion(tccProfileResult)
                    })
                } else {
                    completion(TCCProfileImportResult.failure(TCCProfileImportError.unableToOpenFile))
                }
            }
        }

    }

    /// Mapping & Decoding tcc profile
    ///
    /// - Parameter fileUrl: path with a file to load, completion: TCCProfileImportCompletion - success with TCCProfile or failure with TCCProfileImport Error
    func decodeTCCProfile(fileUrl: URL, _ completion: @escaping TCCProfileImportCompletion) {
        let contents: Data
        do {
            contents = try Data(contentsOf: fileUrl)
        } catch {
            return completion(TCCProfileImportResult.failure(TCCProfileImportError.unableToOpenFile))
        }

        var unsignedResult = self.unsignTCCProfile(fileData: contents)

        if unsignedResult == nil {
            unsignedResult = contents
        }

        guard let tccProfileData = unsignedResult else {
            return completion(TCCProfileImportResult.failure(TCCProfileImportError.decodeProfileError))
        }

        let decoder = PropertyListDecoder()

        do {
            let tccProfile = try decoder.decode(TCCProfile.self, from: tccProfileData)
            return completion(TCCProfileImportResult.success(tccProfile))
        } catch let DecodingError.keyNotFound(codingKey, _) {
            return completion(TCCProfileImportResult.failure(TCCProfileImportError.invalidProfileFile(description: codingKey.stringValue)))
        } catch let DecodingError.typeMismatch(type, context) {
            let errorDescription = "Type \(type) mismatch: \(context.debugDescription) codingPath: \(context.codingPath)"
            return completion(TCCProfileImportResult.failure(TCCProfileImportError.invalidProfileFile(description: errorDescription)))
        } catch let error as NSError {
            let errorDescription = error.userInfo["NSDebugDescription"] as? String
            return completion(TCCProfileImportResult.failure(TCCProfileImportError.invalidProfileFile(description: errorDescription ?? error.localizedDescription)))
        }
    }

    func unsignTCCProfile(fileData data: Data) -> Data? {
        guard let swiftyCMSDecoder = SwiftyCMSDecoder() else {
            return nil
        }

        swiftyCMSDecoder.updateMessage(data: data as NSData)
        swiftyCMSDecoder.finaliseMessage()

        guard let data = swiftyCMSDecoder.data else {
            return nil
        }

        return data
    }
}
