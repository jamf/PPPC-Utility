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
    
    let logger = Logger.UploadManager

	struct VerificationInfo {
		let mustSign: Bool
		let organization: String
	}

	enum VerificationError: Error {
		case anyError(String)
	}

	func verifyConnection(authManager: NetworkAuthManager, completionHandler: @escaping (Result<VerificationInfo, VerificationError>) -> Void) {
        logger.info("Checking connection to Jamf Pro server")

		Task {
			let networking = JamfProAPIClient(serverUrlString: serverURL, tokenManager: authManager)
			let result: Result<VerificationInfo, VerificationError>

			do {
				let version = try await networking.getJamfProVersion()

				// Must sign if Jamf Pro is less than v10.7.1
				let mustSign = (version.semantic() < SemanticVersion(major: 10, minor: 7, patch: 1))

				let orgName = try await networking.getOrganizationName()

				result = .success(VerificationInfo(mustSign: mustSign, organization: orgName))
			} catch is AuthError {
                logger.error("Invalid credentials.")
				result = .failure(VerificationError.anyError("Invalid credentials."))
			} catch {
                logger.error("Jamf Pro server is unavailable.")
				result = .failure(VerificationError.anyError("Jamf Pro server is unavailable."))
			}

			completionHandler(result)
		}
	}

	func upload(profile: TCCProfile, authMgr: NetworkAuthManager, siteInfo: (String, String)?, signingIdentity: SigningIdentity?, completionHandler: @escaping (Error?) -> Void) {
        logger.info("Uploading profile: \(profile.displayName)")

		let networking = JamfProAPIClient(serverUrlString: serverURL, tokenManager: authMgr)
		Task {
			let success: Error?
			var identity: SecIdentity?
			if let signingIdentity = signingIdentity {
                logger.info("Signing profile with \(signingIdentity.displayName)")
				identity = signingIdentity.reference
			}

			do {
				let profileData = try profile.jamfProAPIData(signingIdentity: identity, site: siteInfo)

				_ = try await networking.upload(computerConfigProfile: profileData)

				success = nil
                logger.info("Uploaded successfully")
			} catch {
                logger.error("Error creating or uploading profile: \(error.localizedDescription)")
				success = error
			}

			DispatchQueue.main.async {
				completionHandler(success)
			}
		}
	}
}
