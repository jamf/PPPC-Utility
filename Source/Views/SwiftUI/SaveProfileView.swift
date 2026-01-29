//
//  SaveProfileView.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2024 Jamf Software
//

import OSLog
import SwiftUI

/// Sheet view for saving a profile to disk
struct SaveProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let model: Model

    @AppStorage("organization") private var organization = ""
    @State private var payloadName = ""
    @State private var payloadIdentifier = UUID().uuidString
    @State private var payloadDescription = ""
    @State private var selectedIdentity: SigningIdentity?
    @State private var signingIdentities: [SigningIdentity] = []

    private let logger = Logger.SaveViewController

    var body: some View {
        VStack(spacing: 16) {
            Text("Save Profile")
                .font(.headline)

            Form {
                TextField("Organization:", text: $organization)
                TextField("Payload Name:", text: $payloadName)
                TextField("Payload Identifier:", text: $payloadIdentifier)
                TextField("Payload Description:", text: $payloadDescription)

                Picker("Signing Identity:", selection: $selectedIdentity) {
                    Text("Not signed").tag(nil as SigningIdentity?)
                    ForEach(signingIdentities, id: \.self) { identity in
                        Text(identity.displayName).tag(identity as SigningIdentity?)
                    }
                }
            }
            .padding(.vertical)

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save...") {
                    saveProfile()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 450)
        .onAppear {
            loadIdentities()
            loadImportedProfileInfo()
        }
    }

    private var isValid: Bool {
        !organization.isEmpty && !payloadName.isEmpty && !payloadIdentifier.isEmpty
    }

    private func loadIdentities() {
        do {
            signingIdentities = try SecurityWrapper.loadSigningIdentities()
        } catch {
            logger.error("Error loading identities: \(error)")
        }
    }

    private func loadImportedProfileInfo() {
        if let tccProfile = model.importedTCCProfile {
            organization = tccProfile.organization
            payloadName = tccProfile.displayName
            payloadDescription = tccProfile.payloadDescription
            payloadIdentifier = tccProfile.identifier
        }
    }

    private func saveProfile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "mobileconfig")!]
        panel.nameFieldStringValue = payloadName
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            panel.directoryURL = URL(fileURLWithPath: path, isDirectory: true)
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let profile = model.exportProfile(
            organization: organization,
            identifier: payloadIdentifier,
            displayName: payloadName,
            payloadDescription: payloadDescription.isEmpty ? payloadName : payloadDescription
        )

        do {
            var outputData = try profile.xmlData()
            if let identity = selectedIdentity, let ref = identity.reference {
                logger.info("Signing profile with \(identity.displayName)")
                outputData = try SecurityWrapper.sign(data: outputData, using: ref)
            }
            try outputData.write(to: url)
            logger.info("Saved successfully to \(url.path)")
            dismiss()
        } catch {
            logger.error("Error saving profile: \(error)")
        }
    }
}

#Preview {
    SaveProfileView(model: Model.shared)
}
