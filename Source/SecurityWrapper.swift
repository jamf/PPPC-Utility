//
//  SecurityWrapper.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2023 Jamf Software
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
import Haversack

struct SecurityWrapper {

    static func execute(block: () -> (OSStatus)) throws {
        let status = block()
        if status != 0 {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }

    static func saveCredentials(username: String, password: String, server: String) throws {
		let haversack = Haversack()
		let item = InternetPasswordEntity()
		item.server = server
		item.account = username
		item.passwordData = password.data(using: .utf8)

		try haversack.save(item, itemSecurity: .standard, updateExisting: true)
    }

    static func removeCredentials(server: String, username: String) throws {
		let haversack = Haversack()
		let query = InternetPasswordQuery(server: server)
			.matching(account: username)

		try haversack.delete(where: query, treatNotFoundAsSuccess: true)
    }

    static func loadCredentials(server: String) throws -> (username: String, password: String)? {
		let haversack = Haversack()
		let query = InternetPasswordQuery(server: server)
			.returning([.attributes, .data])

		if let item = try? haversack.first(where: query),
		   let username = item.account,
		   let passwordData = item.passwordData,
		   let password = String(data: passwordData, encoding: .utf8) {
			return (username: username, password: password)
		}

		return nil
    }

    static func copyDesignatedRequirement(url: URL) throws -> String {
        let flags = SecCSFlags(rawValue: 0)
        var staticCode: SecStaticCode?
        var requirement: SecRequirement?
        var text: CFString?

        try execute { SecStaticCodeCreateWithPath(url as CFURL, flags, &staticCode) }
        try execute { SecCodeCopyDesignatedRequirement(staticCode!, flags, &requirement) }
        try execute { SecRequirementCopyString(requirement!, flags, &text) }

        return text! as String
    }

    static func sign(data: Data, using identity: SecIdentity) throws -> Data {

        var outputData: CFData?
        var encoder: CMSEncoder?
        try execute { CMSEncoderCreate(&encoder) }
        try execute { CMSEncoderAddSigners(encoder!, identity) }
        try execute { CMSEncoderAddSignedAttributes(encoder!, .attrSmimeCapabilities) }
        try execute { CMSEncoderUpdateContent(encoder!, (data as NSData).bytes, data.count) }
        try execute { CMSEncoderCopyEncodedContent(encoder!, &outputData) }

        return outputData! as Data
    }

    @MainActor static func loadSigningIdentities() throws -> [SigningIdentity] {
		let haversack = Haversack()
		let query = IdentityQuery().matching(mustBeValidOnDate: Date()).returning(.reference)

		let identities = try haversack.search(where: query)

		return identities.compactMap {
			guard let secIdentity = $0.reference else {
				return nil
			}

			let name = try? getCertificateCommonName(for: secIdentity)
			return SigningIdentity(name: name ?? "Unknown \(secIdentity.hashValue)",
								   reference: secIdentity)
		}
    }

    static func getCertificateCommonName(for identity: SecIdentity) throws -> String {
        var certificate: SecCertificate?
        var commonName: CFString?
        try execute { SecIdentityCopyCertificate(identity, &certificate) }
        try execute { SecCertificateCopyCommonName(certificate!, &commonName) }
        return commonName! as String
    }
}
