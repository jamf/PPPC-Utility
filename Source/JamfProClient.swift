//
//  JamfProClient.swift
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

struct JamfProClient {

    var urlString: String
    var username: String
    var password: String
    var site: (String, String)?

    init(_ url: String, _ user: String, _ pass: String, _ site: (String, String)? = nil) {
        self.urlString = url
        self.password = pass
        self.username = user
        self.site = site
    }

    func uploadProfile(_ profile: TCCProfile, signingIdentity: SecIdentity?, completionBlock: @escaping (Bool) -> Void) {
        var profileText: String
        do {
            var profileData = try profile.xmlData()
            if let identity = signingIdentity {
                profileData = try SecurityWrapper.sign(data: profileData, using: identity)
            }
            profileText = String(data: profileData, encoding: .utf8) ?? ""
        } catch {
            print("Error encoding profile: \(error)")
            completionBlock(false)
            return
        }

        let root = XMLElement(name: "os_x_configuration_profile")
        let general = XMLElement(name: "general")
        root.addChild(general)

        let payloads = XMLElement(name: "payloads", stringValue: profileText)
        general.addChild(payloads)

        if let site = self.site {
            let sites = XMLElement(name: "site")
            let siteId = XMLElement(name: "id", stringValue: site.0)
            let siteName = XMLElement(name: "name", stringValue: site.1)
            sites.addChild(siteId)
            sites.addChild(siteName)
            general.addChild(sites)
        }

        general.addChild(XMLElement(name: "name", stringValue: profile.displayName))
        general.addChild(XMLElement(name: "description", stringValue: profile.payloadDescription))

        let xml = XMLDocument(rootElement: root)

        sendRequest(endpoint: "osxconfigurationprofiles", data: xml.xmlData) { (statusCode, resultData) in
            let success: Bool = (200 <= statusCode && statusCode <= 299)
            if !success {
                if let text = String(data: resultData, encoding: .utf8) {
                    print("Error (\(statusCode)):\n\(text)")
                } else {
                    print("Unknown error: \(statusCode)")
                }

            }
            completionBlock(success)
        }
    }

    func getJamfProVersion(completionBlock: @escaping ((major: Int, minor: Int, patch: Int)?) -> Void) {
        sendRequest(endpoint: nil, data: nil) { (_, data) in
            var result: (major: Int, minor: Int, patch: Int)?
            if let text = String(data: data, encoding: .utf8),
                let startRange = text.range(of: "<meta name=\"version\" content=\""),
                let endRange = text.range(of: "-", options: [], range: startRange.upperBound..<text.endIndex, locale: nil) {
                let val = text[startRange.upperBound..<endRange.lowerBound]
                let versionParts = val.split(separator: ".")
                if versionParts.count == 3,
                    let major = Int(versionParts[0]),
                    let minor = Int(versionParts[1]),
                    let patch = Int(versionParts[2]) {
                    result = (major: major, minor: minor, patch: patch)
                }
            }
            completionBlock(result)
        }
    }

    func getOrganizationName(completionBlock: @escaping (_ httpStatus: Int, _ organizationName: String?) -> Void) {
        sendRequest(endpoint: "activationcode", data: nil) { (statusCode, data) in
            var orgName: String?
            if let doc = try? XMLDocument(data: data, options: []),
                let nodes = try? doc.nodes(forXPath: "/activation_code/organization_name"),
                let name = nodes.first?.stringValue {
                orgName = name
            }
            completionBlock(statusCode, orgName)
        }
    }

    func sendRequest(endpoint: String?, data: Data?, completionHandler: @escaping (_ statusCode: Int, _ output: Data) -> Void) {
        let failureBlock: (String) -> Void = {
            print("\($0)")
            completionHandler(0, Data())
        }

        guard let serverURL = URL(string: urlString) else {
            failureBlock("Failed to create url for: \(urlString)")
            return
        }
        var url = serverURL
        var headers: [String: String] = [:]
        if let apiEndpoint = endpoint {
            url = serverURL.appendingPathComponent("JSSResource/\(apiEndpoint)")
            let encodedText = "\(username):\(password)".data(using: .utf8)?.base64EncodedString() ?? ""
            headers = [
                "Content-Type": "text/xml",
                "Accept": "application/xml",
                "Authorization": "Basic \(encodedText)"
            ]
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        request.allHTTPHeaderFields = headers

        if let body = data {
            request.httpMethod = "POST"
            request.httpBody = body
        } else {
            request.httpMethod = "GET"
        }

        URLSession.shared.dataTask(with: request) { (possibleData, possibleResponse, possibleError) in
            if let error = possibleError {
                failureBlock("Error: \(error)")
            } else if let response = possibleResponse as? HTTPURLResponse {
                completionHandler(response.statusCode, possibleData ?? Data())
            } else {
                failureBlock("Response was nil")
            }
        }.resume()
    }
}
