//
//  TCCProfileViewController.swift
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

class TCCProfileViewController: NSViewController {
    
    @objc dynamic var model = Model.shared
    @objc dynamic var canEdit = true

    @IBOutlet weak var executablesTable: NSTableView!
    @IBOutlet weak var executablesAC: NSArrayController!
    
    @IBOutlet weak var appleEventsTable: NSTableView!
    @IBOutlet weak var appleEventsAC: NSArrayController!
    
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet weak var identifierLabel: NSTextField!
    @IBOutlet weak var codeRequirementLabel: NSTextField!
    
    @IBOutlet weak var addressBookPopUp: NSPopUpButton!
    @IBOutlet weak var photosPopUp: NSPopUpButton!
    @IBOutlet weak var remindersPopUp: NSPopUpButton!
    @IBOutlet weak var calendarPopUp: NSPopUpButton!
    @IBOutlet weak var accessibilityPopUp: NSPopUpButton!
    @IBOutlet weak var postEventsPopUp: NSPopUpButton!
    @IBOutlet weak var adminFilesPopUp: NSPopUpButton!
    @IBOutlet weak var allFilesPopUp: NSPopUpButton!
    @IBOutlet weak var cameraPopUp: NSPopUpButton!
    @IBOutlet weak var microphonePopUp: NSPopUpButton!
    @IBOutlet weak var fileProviderPresencePopUp: NSPopUpButton!
    @IBOutlet weak var listenEventPopUp: NSPopUpButton!
    @IBOutlet weak var mediaLibraryPopUp: NSPopUpButton!
    @IBOutlet weak var screenCapturePopUp: NSPopUpButton!
    @IBOutlet weak var speechRecognitionPopUp: NSPopUpButton!
    @IBOutlet weak var dekstopFolderPopUp: NSPopUpButton!
    @IBOutlet weak var documentsFolderPopUp: NSPopUpButton!
    @IBOutlet weak var downloadsFolderPopUp: NSPopUpButton!
    @IBOutlet weak var networkVolumesPopUp: NSPopUpButton!
    @IBOutlet weak var removableVolumesPopUp: NSPopUpButton!

    @IBOutlet weak var addressBookPopUpAC: NSArrayController!
    @IBOutlet weak var photosPopUpAC: NSArrayController!
    @IBOutlet weak var remindersPopUpAC: NSArrayController!
    @IBOutlet weak var calendarPopUpAC: NSArrayController!
    @IBOutlet weak var accessibilityPopUpAC: NSArrayController!
    @IBOutlet weak var postEventsPopUpAC: NSArrayController!
    @IBOutlet weak var adminFilesPopUpAC: NSArrayController!
    @IBOutlet weak var allFilesPopUpAC: NSArrayController!
    @IBOutlet weak var cameraPopUpAC: NSArrayController!
    @IBOutlet weak var microphonePopUpAC: NSArrayController!
    @IBOutlet weak var fileProviderPresencePopUpAC: NSArrayController!
    @IBOutlet weak var listenEventPopUpAC: NSArrayController!
    @IBOutlet weak var mediaLibraryPopUpAC: NSArrayController!
    @IBOutlet weak var screenCapturePopUpAC: NSArrayController!
    @IBOutlet weak var speechRecognitionPopUpAC: NSArrayController!
    @IBOutlet weak var dekstopFolderPopUpAC: NSArrayController!
    @IBOutlet weak var documentsFolderPopUpAC: NSArrayController!
    @IBOutlet weak var downloadsFolderPopUpAC: NSArrayController!
    @IBOutlet weak var networkVolumesPopUpAC: NSArrayController!
    @IBOutlet weak var removableVolumesPopUpAC: NSArrayController!

    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var uploadButton: NSButton!
    @IBOutlet weak var addAppleEventButton: NSButton!
    @IBOutlet weak var removeAppleEventButton: NSButton!
    
    @IBOutlet weak var recordButton: NSButton!

    @IBAction func recordPressed(_ sender: NSButton) {
        canEdit = !canEdit
        if canEdit {
            recordButton.title = "Record"
        } else {
            recordButton.title = "Stop"
        }
    }
    
    @IBAction func addToProfile(_ sender: NSButton) {
        promptForExecutables {
            self.model.selectedExecutables.append($0)
        }
    }
    
    //  Binding currently deletes at index
    @IBAction func removeButtonPressed(_ sender: NSButton) {
    }

    @IBAction func addToExecutable(_ sender: NSButton) {
        promptForExecutables {
            self.insetIntoAppleEvents($0)
        }
    }
    
    func promptForExecutables(_ block: @escaping (Executable) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = [ kUTTypeBundle, kUTTypeExecutable ] as [String]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.begin { response in
            if response == .OK {
                panel.urls.forEach {
                    guard let executable = self.model.loadExecutable(url: $0) else { return }
                    block(executable)
                }
            }
        }
    }
    
    let pasteboardOptions: [NSPasteboard.ReadingOptionKey : Any] = [
        .urlReadingContentsConformToTypes: [ kUTTypeBundle, kUTTypeExecutable ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Setup policy pop up
        setupAllowDeny(policies: [addressBookPopUpAC,
                                  photosPopUpAC,
                                  remindersPopUpAC,
                                  calendarPopUpAC,
                                  accessibilityPopUpAC,
                                  postEventsPopUpAC,
                                  adminFilesPopUpAC,
                                  allFilesPopUpAC,
                                  fileProviderPresencePopUpAC,
                                  mediaLibraryPopUpAC,
                                  speechRecognitionPopUpAC,
                                  dekstopFolderPopUpAC,
                                  documentsFolderPopUpAC,
                                  downloadsFolderPopUpAC,
                                  networkVolumesPopUpAC,
                                  removableVolumesPopUpAC])

        setupDenyOnly(policies: [cameraPopUpAC,
                                 microphonePopUpAC,
                                 listenEventPopUpAC,
                                 screenCapturePopUpAC])


        //  Setup table views
        executablesTable.registerForDraggedTypes([.fileURL])
        executablesTable.dataSource = self
        appleEventsTable.registerForDraggedTypes([.fileURL])
        appleEventsTable.dataSource = self
        
        //  Record button
    }

    private func setupAllowDeny(policies: [NSArrayController]) {
        for policy in policies {
            policy.add(contentsOf: ["-", "Allow", "Deny"])
        }
    }

    private func setupDenyOnly(policies: [NSArrayController]) {
        for policy in policies {
            policy.add(contentsOf: ["-", "Deny"])
        }
    }
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let openVC = segue.destinationController as? OpenViewController else { return }
        if let button = sender as? NSButton, button == addAppleEventButton {
            Model.shared.current = executablesAC.selectedObjects.first as? Executable
            openVC.completionBlock = {
                $0.forEach { self.insetIntoAppleEvents($0) }
            }
        }
    }
    
    func insetIntoAppleEvents(_ executable: Executable) {
        guard let source = self.executablesAC.selectedObjects.first as? Executable else { return }
        let rule = AppleEventRule()
        rule.source = source
        rule.destination = executable
        guard self.appleEventsAC.canInsert else { return }
        self.appleEventsAC.insert(rule, atArrangedObjectIndex: 0)
    }
    
}

extension TCCProfileViewController : NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        let accept = info.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: pasteboardOptions)
        return accept ? .copy : NSDragOperation()
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard
        
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: pasteboardOptions) as? [URL]? else {
            return false
        }
        
        guard let url = urls?.first else { return false  }
        
        guard let newExecutable = model.loadExecutable(url: url) else { return false }
        
        if tableView == executablesTable {
            guard executablesAC.canInsert else { return false }
            executablesAC.insert(newExecutable, atArrangedObjectIndex: row)
        } else {
            self.insetIntoAppleEvents(newExecutable)
        }
        return true
    }
    
}

