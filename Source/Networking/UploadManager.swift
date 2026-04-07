//
//  UploadManager.swift
//  PPPC Utility
//
//  Created by Kyle Hammond on 11/3/23.
//  Copyright © 2023 Jamf. All rights reserved.
//

import Foundation
import OSLog

struct UploadManager {
    let serverURL: String
    let session: URLSession

    let logger = Logger.UploadManager

    struct VerificationInfo {
        let mustSign: Bool
        let organization: String
    }

    enum VerificationError: Error {
        case anyError(String)
    }

    init(serverURL: String, session: URLSession = .shared) {
        self.serverURL = serverURL
        self.session = session
    }

    func verifyConnection(authManager: NetworkAuthManager) async throws -> VerificationInfo {
        logger.info("Checking connection to Jamf Pro server")

        let networking = JamfProAPIClient(serverUrlString: serverURL, tokenManager: authManager, session: session)

        do {
            let version = try await networking.getJamfProVersion()

            // Must sign if Jamf Pro is less than v10.7.1
            let mustSign = (version.semantic() < SemanticVersion(major: 10, minor: 7, patch: 1))

            let orgName = try await networking.getOrganizationName()

            return VerificationInfo(mustSign: mustSign, organization: orgName)
        } catch is AuthError {
            logger.error("Invalid credentials.")
            throw VerificationError.anyError("Invalid credentials.")
        } catch {
            logger.error("Jamf Pro server is unavailable.")
            throw VerificationError.anyError("Jamf Pro server is unavailable.")
        }
    }

    func upload(profile: TCCProfile, authMgr: NetworkAuthManager, siteInfo: (String, String)?, signingIdentity: SigningIdentity?) async throws {
        logger.info("Uploading profile: \(profile.displayName, privacy: .public)")

        let networking = JamfProAPIClient(serverUrlString: serverURL, tokenManager: authMgr, session: session)
        var identity: SecIdentity?
        if let signingIdentity = signingIdentity {
            logger.info("Signing profile with \(signingIdentity.displayName)")
            identity = signingIdentity.reference
        }

        let profileData = try await profile.jamfProAPIData(signingIdentity: identity, site: siteInfo)

        _ = try await networking.upload(computerConfigProfile: profileData)

        logger.info("Uploaded successfully")
    }
}
