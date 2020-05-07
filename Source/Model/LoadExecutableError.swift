//
//  LoadExecutableError.swift
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
public enum LoadExecutableError: Error {
    case identifierNotFound
    case resourceURLNotFound
    case codeRequirementError(description: String)
    case executableNotFound
    case executableAlreadyExists
}

extension LoadExecutableError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .identifierNotFound:
            return "Bundle identifier could not be found."
        case .resourceURLNotFound:
            return "Resource URL could not be found."
        case .codeRequirementError(let description):
            return "Failed to get designated code requirement. The executable may not be signed. Error: \(description)"
        case .executableNotFound:
            return "Could not find executable from url path"
        case .executableAlreadyExists:
            return "The executable is already loaded."
        }
    }
}
