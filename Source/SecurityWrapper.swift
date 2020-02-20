//
//  SecurityWrapper.swift
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

import Foundation

struct SecurityWrapper {
    
    static func execute(block: ()->(OSStatus)) throws {
        let status = block()
        if status != 0 {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
    
    static func saveCredentials(username: String, password: String, server: String) throws {
        
        do {
            let possibleResult = try loadCredentials(server: server)
            if let old = possibleResult, username == old.username && password == old.password {
                return
            } else {
                let dict = [
                    kSecClass as String: kSecClassInternetPassword,
                    kSecAttrServer as String: server,
                    kSecAttrAccount as String: username
                ] as CFDictionary
                try execute { SecItemDelete(dict) }
            }
        } catch {}
        
        let dict = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecAttrAccount as String: username,
            kSecValueData as String: password
        ] as CFDictionary
        try execute { SecItemAdd(dict, nil) }
    }
    
    static func removeCredentials(server: String, username: String) throws {
        let dict = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecAttrAccount as String: username
        ] as CFDictionary
        try execute { SecItemDelete(dict) }
    }
    
    static func loadCredentials(server: String) throws -> (username: String, password: String)? {
        let dict = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ] as CFDictionary

        var item: CFTypeRef?
        try execute {
            let status = SecItemCopyMatching(dict, &item)
            //  Check if success or not found, thrown error is a "real" error
            if status == errSecSuccess || status == errSecItemNotFound {
                return errSecSuccess
            }
            return status
        }
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: .utf8),
            let username = existingItem[kSecAttrAccount as String] as? String
            else {
                return nil
        }
        return (username: username, password: password)
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
        try execute { CMSEncoderAddSigners(encoder!,identity) }
        try execute { CMSEncoderAddSignedAttributes(encoder!,.attrSmimeCapabilities) }
        try execute { CMSEncoderUpdateContent(encoder!,(data as NSData).bytes,data.count) }
        try execute { CMSEncoderCopyEncodedContent(encoder!,&outputData) }
        
        return outputData! as Data
    }
    
    static func loadSigningIdentities() throws -> [SigningIdentity] {
        
        let dict = [
            kSecClass as String         : kSecClassIdentity,
            kSecReturnRef as String     : kCFBooleanTrue!,
            kSecMatchLimit as String    : kSecMatchLimitAll
        ] as CFDictionary
        
        var result: AnyObject?
        try execute { SecItemCopyMatching(dict, &result) }
        
        guard let secIdentities = result as? [SecIdentity] else { return [] }
        
        return secIdentities.map({
            let name = try? getCertificateCommonName(for: $0)
            return SigningIdentity(name: name ?? "Unknown \($0.hashValue)", reference: $0)
        })
    }
    
    static func getCertificateCommonName(for identity: SecIdentity) throws -> String {
        var certificate: SecCertificate?
        var commonName: CFString?
        try execute { SecIdentityCopyCertificate(identity, &certificate) }
        try execute { SecCertificateCopyCommonName(certificate!, &commonName) }
        return commonName! as String
    }
}
