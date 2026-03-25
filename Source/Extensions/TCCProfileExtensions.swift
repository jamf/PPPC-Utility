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

extension TCCProfile {

    public enum ParseError: Error {
        case failedToCreateDecoder
    }

    /// Create a ``TCCProfile`` object from a `Data` containing a provisioning profile.
    /// - Parameter profileData: The raw profile data (generally from a file read operation).  This may be CMS encoded.
    /// - Returns: A ``TCCProfile`` instance.
    /// - Throws: Either a ``TCCProfile.ParseError`` or a `DecodingError`.
    public static func parse(from profileData: Data) throws -> TCCProfile {
        // The profile may be CMS encoded; let's try to decode it.
        guard let cmsDecoder = SwiftyCMSDecoder() else {
            throw ParseError.failedToCreateDecoder
        }
        cmsDecoder.updateMessage(data: profileData as NSData)
        cmsDecoder.finaliseMessage()

        var plistData: Data
        if let decodedData = cmsDecoder.data {
            // Use the decoded data if CMS decoding worked.
            plistData = decodedData
        } else {
            // Assume it failed because it's not encrypted and move on to deserialize with original data.
            plistData = profileData
        }

        // Adjust letter case of required keys to be more flexible during import.
        plistData = fixLetterCase(of: plistData)

        return try PropertyListDecoder().decode(TCCProfile.self, from: plistData)
    }

    /// Adjust the letter case of required profile keys to meet the standard during import.
    /// - Parameter original: The original data from the file
    /// - Returns: (Possibly) updated data with all of the required profile keys meeting the standard letter case.
    private static func fixLetterCase(of original: Data) -> Data {
        guard let originalString = String(data: original, encoding: .utf8) else {
            return original
        }
        var newString = originalString

        // This block looks for the given coding key within a property list XML string and
        // converts it to the standard letter case.
        let conversionBlock = { (codingKey: CodingKey) in
            let requiredString = ">\(codingKey.stringValue)<"
            newString = newString.replacingOccurrences(
                of: requiredString,
                with: requiredString,
                options: .caseInsensitive)
        }

        // Currently there are three model structs that are used to decode the profile.
        TCCProfile.CodingKeys.allCases.forEach(conversionBlock)
        TCCProfile.Content.CodingKeys.allCases.forEach(conversionBlock)
        TCCPolicy.CodingKeys.allCases.forEach(conversionBlock)

        // Convert the String back to Data
        guard let newData = newString.data(using: .utf8) else {
            return original
        }

        return newData
    }
}
