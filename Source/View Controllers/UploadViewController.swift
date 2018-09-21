//
//  UploadViewController.swift
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

import Cocoa
import CoreGraphics

class UploadViewController: NSViewController {
    
    private static var uploadKVOContext = 0
    
    @objc dynamic var networkOperationsTitle: String! = nil
    @objc dynamic var mustSignForUpload: Bool = true {
        didSet {
            let containsNullRef = (identitiesPopUpAC.arrangedObjects as? [SigningIdentity])?.first?.reference == nil
            if mustSignForUpload && containsNullRef {
                identitiesPopUpAC.remove(atArrangedObjectIndex: 0)
            } else if !mustSignForUpload && !containsNullRef {
                let nullRef = SigningIdentity(name: "Profile signed by server", reference: nil)
                identitiesPopUpAC.insert(nullRef, atArrangedObjectIndex: 0)
            }
        }
    }

    @objc dynamic var credentialsAvailable = false
    @objc dynamic var credentialsVerified = false
    @objc dynamic var saveCredentials = true
    @objc dynamic var readyForUpload = false

    @objc dynamic var username: String!
    @objc dynamic var password: String!
    @objc dynamic var payloadName: String!
    @objc dynamic var payloadIdentifier: String! = UUID().uuidString
    @objc dynamic var payloadDescription: String!

    @IBOutlet weak var defaultsController: NSUserDefaultsController!
    
    @IBOutlet weak var jamfProServerLabel: NSTextField!
    @IBOutlet weak var usernameLabel: NSTextField!
    @IBOutlet weak var passwordLabel: NSSecureTextField!
    @IBOutlet weak var organizationLabel: NSTextField!
    @IBOutlet weak var payloadNameLabel: NSTextField!
    @IBOutlet weak var payloadIdentifierLabel: NSTextField!
    @IBOutlet weak var payloadDescriptionLabel: NSTextField!
    @IBOutlet weak var identitiesPopUp: NSPopUpButton!
    @IBOutlet var identitiesPopUpAC: NSArrayController!
    @IBOutlet weak var uploadButton: NSButton!
    @IBOutlet weak var checkConnectionButton: NSButton!
    
    @IBOutlet weak var gridView: NSGridView!
    
    @IBAction func uploadPressed(_ sender: NSButton) {
        print("Uploading profile: \(payloadName ?? "?")")
        self.networkOperationsTitle = "Uploading \(payloadName ?? "profile")"

        let model = Model.shared
        let profile = model.exportProfile(organization: organizationLabel.stringValue,
                                          identifier: payloadIdentifierLabel.stringValue,
                                          displayName: payloadNameLabel.stringValue,
                                          payloadDescription: payloadDescriptionLabel.stringValue)
        var identity: SecIdentity?
        if mustSignForUpload, let signingIdentity = identitiesPopUpAC.selectedObjects.first as? SigningIdentity, signingIdentity.reference != nil {
            print("Signing profile with \(signingIdentity.displayName)")
            identity = signingIdentity.reference
        }
        
        JamfProClient(jamfProServerLabel.stringValue, username, password).uploadProfile(profile, signingIdentity: identity) { (success) in
            DispatchQueue.main.async {
                self.handleUploadCompletion(success: success)
            }
        }
    }
    
    @IBAction func checkConnectionPressed(_ sender: NSButton) {
        print("Checking connection")
        self.networkOperationsTitle = "Checking Jamf Pro server"
        
        let client = JamfProClient(jamfProServerLabel.stringValue, username, password)
        
        client.getJamfProVersion { (possibleVersion) in
            if let version = possibleVersion {
                print("Jamf Pro Server: \(version.major).\(version.minor).\(version.patch)")
                let mustSign: Bool =
                    (version.major < 10 ||
                        (version.major == 10 &&
                            (version.minor < 7 ||
                                (version.minor == 7 && version.patch == 0))))
                client.getOrganizationName { (statusCode, orgName) in
                    if statusCode == 401 {
                        print("Invalid username/password")
                        DispatchQueue.main.async {
                            self.handleCheckConnectionFailure(enforceSigning: mustSign)
                        }
                    } else if let name = orgName {
                        DispatchQueue.main.async {
                            self.handleCheckConnection(enforceSigning: mustSign,
                                                       organization: name)
                        }
                    } else {
                        print("Unable to read organization name")
                        DispatchQueue.main.async {
                            self.handleCheckConnectionFailure(enforceSigning: mustSign)
                        }
                    }
                }
            } else {
                print("Jamf Pro server is unavailable")
                DispatchQueue.main.async {
                    self.handleCheckConnectionFailure(enforceSigning: nil)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkConnectionButton.isEnabled = false
        organizationLabel.isEnabled = false
        payloadNameLabel.isEnabled = false
        payloadIdentifierLabel.isEnabled = false
        payloadDescriptionLabel.isEnabled = false
        
        do {
            let identities = try SecurityWrapper.loadSigningIdentities()
            identitiesPopUpAC.add(contentsOf: identities)
        } catch {
            identitiesPopUpAC.add(contentsOf: [])
            print("Error loading identities: \(error)")
        }
        
        mustSignForUpload = UserDefaults.standard.bool(forKey: "enforceSigning")
        
        loadCredentials()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        defaultsController.addObserver(self, forKeyPath: "values.jamfProServer", options: [.new], context: &UploadViewController.uploadKVOContext)
        defaultsController.addObserver(self, forKeyPath: "values.organization", options: [.new], context: &UploadViewController.uploadKVOContext)
        addObserver(self, forKeyPath: "username", options: [.new], context: &UploadViewController.uploadKVOContext)
        addObserver(self, forKeyPath: "password", options: [.new], context: &UploadViewController.uploadKVOContext)
        addObserver(self, forKeyPath: "payloadName", options: [.new], context: &UploadViewController.uploadKVOContext)
        addObserver(self, forKeyPath: "payloadDescription", options: [.new], context: &UploadViewController.uploadKVOContext)
        addObserver(self, forKeyPath: "payloadIdentifier", options: [.new], context: &UploadViewController.uploadKVOContext)
    
        if organizationLabel.stringValue.isEmpty {
            organizationLabel.becomeFirstResponder()
        } else if credentialsAvailable {
            payloadNameLabel.becomeFirstResponder()
        } else {
            usernameLabel.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        defaultsController.removeObserver(self, forKeyPath: "values.jamfProServer", context: &UploadViewController.uploadKVOContext)
        defaultsController.removeObserver(self, forKeyPath: "values.organization", context: &UploadViewController.uploadKVOContext)
        removeObserver(self, forKeyPath: "username", context: &UploadViewController.uploadKVOContext)
        removeObserver(self, forKeyPath: "password", context: &UploadViewController.uploadKVOContext)
        removeObserver(self, forKeyPath: "payloadName", context: &UploadViewController.uploadKVOContext)
        removeObserver(self, forKeyPath: "payloadDescription", context: &UploadViewController.uploadKVOContext)
        removeObserver(self, forKeyPath: "payloadIdentifier", context: &UploadViewController.uploadKVOContext)

        
        //  Save keychain
        syncronizeCredentials()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &UploadViewController.uploadKVOContext {
            updateCredentialsAvailable()
            updateReadForUpload()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func updateCredentialsAvailable() {
        guard credentialsAvailable != (
            !jamfProServerLabel.stringValue.isEmpty
            && (username != nil)
            && !username.isEmpty
            && (password != nil)
            && !password.isEmpty) else { return }
        credentialsAvailable = !credentialsAvailable
    }
    
    func updateReadForUpload() {
        guard readyForUpload != (
            credentialsVerified
            && credentialsAvailable
            && !organizationLabel.stringValue.isEmpty
            && (payloadName != nil)
            && !payloadName.isEmpty
            && (payloadIdentifier != nil)
            && !payloadIdentifier.isEmpty) else { return }
        readyForUpload = !readyForUpload
    }
    
    func handleCheckConnectionFailure(enforceSigning: Bool?) {
        identitiesPopUp.isEnabled = enforceSigning ?? false
        networkOperationsTitle = nil
        credentialsVerified = false
        updateReadForUpload()
        passwordLabel.becomeFirstResponder()
    }
    
    func handleCheckConnection(enforceSigning: Bool, organization: String) {
        defaultsController.setValue(organization, forKeyPath: "values.organization")
        UserDefaults.standard.set(enforceSigning, forKey: "enforceSigning")
        networkOperationsTitle = nil
        mustSignForUpload = enforceSigning
        syncronizeCredentials()
        credentialsVerified = true
        payloadNameLabel.becomeFirstResponder()
        updateReadForUpload()
    }
    
    func handleUploadCompletion(success: Bool) {
        guard !success else {
            print("Uploaded successfully")
            self.dismiss(nil)
            return
        }
        
        print("Failed to upload")
        
        networkOperationsTitle = nil
        credentialsVerified = false
        passwordLabel.becomeFirstResponder()
        updateReadForUpload()
    }
    
    func loadCredentials() {
        if let server = UserDefaults.standard.string(forKey: "jamfProServer") {
            do {
                let possibleCredentials = try SecurityWrapper.loadCredentials(server: server)
                if let credentials = possibleCredentials {
                    username = credentials.username
                    password = credentials.password
                    credentialsAvailable = true
                    credentialsVerified = true
                    return
                }
            } catch {
                print("Error loading credentials: \(error)")
            }
        }
        
        username = nil
        password = nil
        credentialsAvailable = false
        credentialsVerified = false
    }

    
    func syncronizeCredentials() {
        if saveCredentials {
            if credentialsAvailable {
                do {
                    try SecurityWrapper.saveCredentials(username: username,
                                                        password: password,
                                                        server: jamfProServerLabel.stringValue)
                } catch {
                    print("Failed to save credentials with error: \(error)")
                }
            }
        } else {
            try? SecurityWrapper.removeCredentials(server: jamfProServerLabel.stringValue, username: username)
        }
    }
}
