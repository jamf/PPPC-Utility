//
//  UploadInfoView.swift
//  PPPC Utility
//
//  SPDX-License-Identifier: MIT
//  Copyright (c) 2023 Jamf Software

import OSLog
import SwiftUI

struct UploadInfoView: View {
	/// The signing identities available to be used.
	let signingIdentities: [SigningIdentity]
	/// Function to call when this view needs to be removed
	let dismissAction: (() -> Void)?

	// Communicate this info to the user
	@State private var warningInfo: String?
	@State private var networkOperationInfo: String?
	///	Must sign the profile if Jamf Pro is less than v10.7.1
	@State private var mustSign = false
	/// The hash of connection info that has been verified with a succesful connection
	@State private var verifiedConnectionHash: Int = 0

	// MARK: User entry fields
	@AppStorage("jamfProServer") private var serverURL = "https://"
	@AppStorage("organization") private var organization = ""
	@AppStorage("authType") private var authType = AuthenticationType.clientCredentials

	@State private var username = ""
	@State private var password = ""
	@State private var saveToKeychain: Bool = true
	@State private var payloadName = ""
	@State private var payloadId = UUID().uuidString
	@State private var payloadDescription = ""
	@State private var signingId: SigningIdentity?
	@State private var useSite: Bool = false
	@State private var siteId: Int = -1
	@State private var siteName: String = ""

    	let logger = Logger.UploadInfoView

	/// The type of authentication the user wants to use.
	///
	/// `String` type so it can be saved with `@AppStorage` above
	enum AuthenticationType: String {
		case basicAuth
		case clientCredentials
	}

	let intFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .none
		return formatter
	}()

	var body: some View {
		VStack {
			Form {
				TextField("Jamf Pro Server *:", text: $serverURL)
				Picker("Authorization Type:", selection: $authType) {
					Text("Basic/Bearer Auth").tag(AuthenticationType.basicAuth)
					Text("Client Credentials (v10.49+):").tag(AuthenticationType.clientCredentials)
				}
				TextField(authType == .basicAuth ? "Username *:" : "Client ID *:", text: $username)
				SecureField(authType == .basicAuth ? "Password *:" : "Client Secret *:", text: $password)

				HStack {
					Toggle("Save in Keychain", isOn: $saveToKeychain)
						.help("Store the username & password or client id & secret in the login keychain")
					if verifiedConnection {
						Spacer()
						Text("✔️ Verified")
							.font(.footnote)
					}
				}
				Divider()
					.padding(.vertical)

				TextField("Organization *:", text: $organization)
				TextField("Payload Name *:", text: $payloadName)
				TextField("Payload Identifier *:", text: $payloadId)
				TextField("Payload Description:", text: $payloadDescription)
				Picker("Signing Identity:", selection: $signingId) {
					Text("Profile signed by server").tag(nil as SigningIdentity?)
					ForEach(signingIdentities, id: \.self) { identity in
						Text(identity.displayName).tag(identity)
					}
				}
				.disabled(!mustSign)
				Toggle("Use Site", isOn: $useSite)
				TextField("Site ID", value: $siteId, formatter: intFormatter)
					.disabled(!useSite)
				TextField("Site Name", text: $siteName)
					.disabled(!useSite)
			}
			.padding(.bottom)

			if let warning = warningInfo {
				Text(warning)
					.font(.headline)
					.foregroundColor(.red)
			}
			if let networkInfo = networkOperationInfo {
				HStack {
					Text(networkInfo)
						.font(.headline)
					ProgressView()
						.padding(.leading)
				}
			}

			HStack {
				Spacer()

				Button("Cancel") {
					dismissView()
				}
				.keyboardShortcut(.cancelAction)

				Button(verifiedConnection ? "Upload" : "Check connection") {
					if verifiedConnection {
						performUpload()
					} else {
						verifyConnection()
					}
				}
				.keyboardShortcut(.defaultAction)
				.disabled(!buttonEnabled())
			}
		}
		.padding()
		.frame(minWidth: 450)
		.background(Color(.windowBackgroundColor))
		.onAppear {
			// Load keychain values
			if let creds = try? SecurityWrapper.loadCredentials(server: serverURL) {
				username = creds.username
				password = creds.password
			}

			// Use model payload values if it was imported
			if let tccProfile = Model.shared.importedTCCProfile {
				organization = tccProfile.organization
				payloadName = tccProfile.displayName
				payloadDescription = tccProfile.payloadDescription
				payloadId = tccProfile.identifier
			}
		}
	}

	/// Creates a hash of the currently entered connection info
	var hashOfConnectionInfo: Int {
		var hasher = Hasher()
		hasher.combine(serverURL)
		hasher.combine(username)
		hasher.combine(password)
		hasher.combine(authType)
		return hasher.finalize()
	}

	/// Compare the last verified connection hash with the current hash of connection info
	var verifiedConnection: Bool {
		verifiedConnectionHash == hashOfConnectionInfo
	}

	func buttonEnabled() -> Bool {
		if verifiedConnection {
			return payloadInfoPassesValidation()
		}
		return connectionInfoPassesValidation()
	}

	private func warning(_ info: StaticString, shouldDisplay: Bool) {
		if shouldDisplay {
            logger.info("\(info)")
			warningInfo = "\(info)"
		}
	}

	/// Does some simple validation of the user-entered connection info
	///
	/// The `setWarningInfo` parameter is optional, and should only be set to `true` during
	/// actions triggered by the user.  This function can be called with `false` (or no parameters)
	/// from SwiftUI's `body` function to enable/disable controls.
	/// - Parameter setWarningInfo: Whether to set the warning text so the user knows something needs to be updated.  Default is `false`.
	/// - Returns: True if the user entered connection info passes simple local validation
	func connectionInfoPassesValidation(setWarningInfo: Bool = false) -> Bool {
		guard !serverURL.isEmpty else {
			warning("Server URL not set", shouldDisplay: setWarningInfo)
			// Future on macOS 12+: focus on serverURL field
			return false
		}

		guard let url = URL(string: serverURL),
			  url.scheme == "http" || url.scheme == "https" else {
			warning("Invalid Jamf Pro Server URL", shouldDisplay: setWarningInfo)
			// Future on macOS 12+: focus on serverURL field
			return false
		}

		if authType == .basicAuth {
			guard !username.isEmpty, !password.isEmpty else {
				warning("Username or password not set", shouldDisplay: setWarningInfo)
				// Future on macOS 12+: focus on username or password field
				return false
			}

			guard username.firstIndex(of: ":") == nil else {
				warning("Username cannot contain a colon", shouldDisplay: setWarningInfo)
				// Future on macOS 12+: focus on username field
				return false
			}
		} else {
			guard !username.isEmpty, !password.isEmpty else {
				warning("Client ID or secret not set", shouldDisplay: setWarningInfo)
				// Future on macOS 12+: focus on username or password field
				return false
			}
		}

		if setWarningInfo {
			warningInfo = nil
		}
		return true
	}

	/// Does some simple validation of the user-entered payload info
	///
	/// The `setWarningInfo` parameter is optional, and should only be set to `true` during
	/// actions triggered by the user.  This function can be called with `false` (or no parameters)
	/// from SwiftUI's `body` function to enable/disable controls.
	/// - Parameter setWarningInfo: Whether to set the warning text so the user knows something needs to be updated.  Default is `false`.
	/// - Returns: True if the user entered payload info passes simple local validation
	func payloadInfoPassesValidation(setWarningInfo: Bool = false) -> Bool {
		guard !organization.isEmpty else {
			warning("Must provide an organization name", shouldDisplay: setWarningInfo)
			// Future on macOS 12+: focus on organization field
			return false
		}

		guard !payloadId.isEmpty else {
			warning("Must provide a payload identifier", shouldDisplay: setWarningInfo)
			// Future on macOS 12+: focus on payload ID field
			return false
		}

		guard !payloadName.isEmpty else {
			warning("Must provide a payload name", shouldDisplay: setWarningInfo)
			// Future on macOS 12+: focus on payloadName field
			return false
		}

		guard useSite == false || (useSite == true && siteId != -1 && !siteName.isEmpty) else {
			warning("Must provide both an ID and name for the site", shouldDisplay: setWarningInfo)
			// Future on macOS 12+: focus on siteId or siteName field
			return false
		}

		if setWarningInfo {
			warningInfo = nil
		}
		return true
	}

	func makeAuthManager() -> NetworkAuthManager {
		if authType == .basicAuth {
			return NetworkAuthManager(username: username, password: password)
		}

		return NetworkAuthManager(clientId: username, clientSecret: password)
	}

	func verifyConnection() {
		guard connectionInfoPassesValidation(setWarningInfo: true) else {
			return
		}

		networkOperationInfo = "Checking Jamf Pro server"

		let uploadMgr = UploadManager(serverURL: serverURL)
		uploadMgr.verifyConnection(authManager: makeAuthManager()) { result in
			if case .success(let success) = result {
				mustSign = success.mustSign
				organization = success.organization
				verifiedConnectionHash = hashOfConnectionInfo
				if saveToKeychain {
					do {
						try SecurityWrapper.saveCredentials(username: username,
															password: password,
															server: serverURL)
					} catch {
                        logger.error("Failed to save credentials with error: \(error.localizedDescription)")
					}
				}
				// Future on macOS 12+: focus on Payload Name field
			} else if case .failure(let failure) = result,
					  case .anyError(let errorString) = failure {
				warningInfo = errorString
				verifiedConnectionHash = 0
			}

			networkOperationInfo = nil
		}
	}

	private func dismissView() {
		if !saveToKeychain {
			try? SecurityWrapper.removeCredentials(server: serverURL, username: username)
		}

		if let dismiss = dismissAction {
			dismiss()
		}
	}

	func performUpload() {
		guard connectionInfoPassesValidation(setWarningInfo: true) else {
			return
		}

		guard payloadInfoPassesValidation(setWarningInfo: true) else {
			return
		}

		let profile = Model.shared.exportProfile(organization: organization,
												 identifier: payloadId,
												 displayName: payloadName,
												 payloadDescription: payloadDescription)

		networkOperationInfo = "Uploading '\(profile.displayName)'..."

		var siteIdAndName: (String, String)?
		if useSite {
			if siteId != -1 && !siteName.isEmpty {
				siteIdAndName = ("\(siteId)", siteName)
			}
		}

		let uploadMgr = UploadManager(serverURL: serverURL)
		uploadMgr.upload(profile: profile,
						 authMgr: makeAuthManager(),
						 siteInfo: siteIdAndName,
						 signingIdentity: mustSign ? signingId : nil) { possibleError in
			if let error = possibleError {
				warningInfo = error.localizedDescription
			} else {
				Alert().display(header: "Success", message: "Profile uploaded succesfully")
				dismissView()
			}
			networkOperationInfo = nil
		}
	}
}

#Preview {
	UploadInfoView(signingIdentities: [],
				   dismissAction: nil)
}
