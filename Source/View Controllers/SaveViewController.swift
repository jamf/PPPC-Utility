//
//  SaveViewController.swift
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

class SaveViewController: NSViewController {
    
    private static var saveProfileKVOContext = 0

    @objc dynamic var isReadyToSave: Bool = false
    
    @objc dynamic var payloadName: String! {
        didSet {
            updateIsReadyToSave()
        }
    }
    
    @objc dynamic var payloadIdentifier: String! {
        didSet {
            updateIsReadyToSave()
        }
    }
    
    @objc dynamic var payloadDescription: String! {
        didSet {
            updateIsReadyToSave()
        }
    }

    @IBOutlet weak var payloadNameLabel: NSTextField!

    @IBOutlet weak var organizationLabel: NSTextField!
    @IBOutlet weak var identitiesPopUp: NSPopUpButton!
    @IBOutlet var identitiesPopUpAC: NSArrayController!
    @IBOutlet weak var saveButton: NSButton!
    
    var defaultsController = NSUserDefaultsController.shared
    
    func updateIsReadyToSave() {
        guard isReadyToSave != (
            !organizationLabel.stringValue.isEmpty
            && (payloadName != nil)
            && !payloadName.isEmpty
            && (payloadIdentifier != nil)
            && !payloadIdentifier.isEmpty ) else { return }
        isReadyToSave = !isReadyToSave
    }
    
    @IBAction func savePressed(_ sender: NSButton) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["mobileconfig"]
        panel.nameFieldStringValue = payloadName
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            panel.directoryURL = URL(fileURLWithPath: path, isDirectory: true)
        }

        panel.begin { response in
            if response == .OK {
                // Let the save panel fully close itself before doing any work that may require keychain access.
                DispatchQueue.main.async {
                    self.saveTo(url: panel.url!)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        payloadIdentifier = UUID().uuidString
        do {
            var identities = try SecurityWrapper.loadSigningIdentities()
            identities.insert(SigningIdentity(name: "Not signed", reference: nil), at: 0)
            identitiesPopUpAC.add(contentsOf: identities)
        } catch {
            print("Error loading identities: \(error)")
        }

        loadImportedTCCProfileInfo()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        defaultsController.addObserver(self, forKeyPath: "values.organization", options: [.new], context: &SaveViewController.saveProfileKVOContext)
        if !organizationLabel.stringValue.isEmpty {
            payloadNameLabel.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        defaultsController.removeObserver(self, forKeyPath: "values.organization", context: &SaveViewController.saveProfileKVOContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &SaveViewController.saveProfileKVOContext {
            updateIsReadyToSave()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func saveTo(url: URL) {
        print("Saving to \(url)")
        let model = Model.shared
        let profile = model.exportProfile(organization: organizationLabel.stringValue,
                                          identifier: payloadIdentifier,
                                          displayName: payloadName,
                                          payloadDescription: payloadDescription ?? payloadName)
        do {
            var outputData = try profile.xmlData()
            if let identity = identitiesPopUpAC.selectedObjects.first as? SigningIdentity, let ref = identity.reference {
                print("Signing profile with \(identity.displayName)")
                outputData = try SecurityWrapper.sign(data: outputData, using: ref)
            }
            try outputData.write(to: url)
            print("Saved successfully")
        } catch {
            print("Error: \(error)")
        }
        self.dismiss(nil)
    }

    func loadImportedTCCProfileInfo() {
        let model = Model.shared

        if let tccProfile = model.importedTCCProfile {
            organizationLabel.stringValue = tccProfile.organization
            payloadName = tccProfile.displayName
            payloadDescription = tccProfile.payloadDescription
            payloadIdentifier = tccProfile.identifier
        }
    }

}
