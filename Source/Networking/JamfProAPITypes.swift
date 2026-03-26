//
//  JamfProAPITypes.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2022 Jamf Software
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

struct JamfProVersion: Decodable, Sendable {
    let version: String

    func mainVersionInfo() -> String {
        return String(version.prefix { character in
            return (character.isNumber || character == ".")
        })
    }

    func semantic() -> SemanticVersion {
        let components = mainVersionInfo().split(separator: ".")

        return SemanticVersion(major: Int(components[0]) ?? 0, minor: Int(components[1]) ?? 0, patch: Int(components[2]) ?? 0)
    }

    /// Versions of Jamf Pro less than 10.23 included the version number in a meta tag on the login page.
    /// - Parameter text: The HTML contents of the login page.
    init(fromHTMLString text: String?) throws {
        // we take version from HTML response body
        if let text = text,
           let startRange = text.range(of: "<meta name=\"version\" content=\""),
           let endRange = text.range(of: "-", options: [], range: startRange.upperBound..<text.endIndex, locale: nil) {
            let val = text[startRange.upperBound..<endRange.lowerBound]
            let versionParts = val.split(separator: ".")
            if versionParts.count == 3,
               let major = Int(versionParts[0]),
               let minor = Int(versionParts[1]),
               let patch = Int(versionParts[2]) {
                version = "\(major).\(minor).\(patch)"
            } else {
                throw NSError(domain: NSCocoaErrorDomain, code: paramErr)
            }
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: paramErr)
        }
    }
}

struct ActivationCode: Decodable, Sendable {
    let activationCode: OrgAndCode

    enum CodingKeys: String, CodingKey {
        case activationCode = "activation_code"
    }

    struct OrgAndCode: Decodable, Sendable {
        let organizationName: String
        let code: String

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case organizationName = "organization_name"
            case code
        }
    }
}
