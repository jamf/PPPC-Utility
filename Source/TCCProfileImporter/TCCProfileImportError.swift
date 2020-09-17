//
//  ConfigProfileImportError.swift
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
public enum TCCProfileImportError: Error {
    case cancelled
    case unableToOpenFile
    case decodeProfileError
    case invalidProfileFile(description: String)
    case emptyFields(description: String)
}

extension TCCProfileImportError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Cancelled the import."
        case .unableToOpenFile:
            return "Unable to open file. Please make sure that file is correct and try again."
        case .decodeProfileError:
            return "Unable to read configuration profile. Please make sure the file is correct and try again."
        case .invalidProfileFile(let description):
            return "Invalid TCC Profile. Please make sure that required keys are inside profile: \(description)"
        case .emptyFields(let description):
            return "Unable to proceed. The following fields are required: \(description)"
        }
    }

    var isCancelled: Bool {
        switch self {
        case .cancelled:
            return true
        default:
            return false
        }
    }
}
