//
//  TCCProfileExtensions.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2020 Jamf Software
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

public extension TCCProfile {

    enum ParseError: Error {
        case failedToCreateDecoder
        case failedToCreateData
    }

    /// Create a Provisioning Profile object from the file's Data.
    static func parse(from profileData: Data) throws -> TCCProfile {

        guard let decoder = SwiftyCMSDecoder() else {
            throw ParseError.failedToCreateDecoder
        }

        decoder.updateMessage(data: profileData as NSData)
        decoder.finaliseMessage()

        var data = decoder.data

        if data == nil {
            // Assume it failed becuase it's not encrypted and move on to deserialize data into TCCProfile object with data as is.
            data = profileData
        }

        return try PropertyListDecoder().decode(TCCProfile.self, from: data!)

    }

}
