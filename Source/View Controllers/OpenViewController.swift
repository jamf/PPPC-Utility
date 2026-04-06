//
//  OpenViewController.swift
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

class OpenViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    var completionBlock: (([LoadExecutableResult]) -> Void)?

    var observers: [NSKeyValueObservation] = []

    @objc dynamic var current: Executable?
    @objc dynamic var choices: [Executable] = []

    @IBOutlet var choicesAC: NSArrayController!
    @IBOutlet weak var choicesTableView: NSTableView!

    override func viewWillAppear() {
        super.viewWillAppear()
        //  Reload executables
        current = Model.shared.current
        choicesTableView.isEnabled = false
        if let value = current {
            Task {
                choices = await Model.shared.getAppleEventChoices(executable: value)
                choicesTableView.isEnabled = true
            }
        }
    }

    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        guard let index = proposedSelectionIndexes.first else { return proposedSelectionIndexes }
        // put the completion block on the MainActor queue and dismiss when done
        Task {
            self.completionBlock?([.success(self.choices[index])])
            self.dismiss(self)
        }
        return proposedSelectionIndexes
    }

    @IBAction func prompt(_ sender: NSButton) {
        let block = completionBlock
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = [kUTTypeBundle, kUTTypeUnixExecutable] as [String]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.begin { response in
            if response == .OK {
                Task {
                    var selections: [LoadExecutableResult] = []
                    for url in panel.urls {
                        do {
                            let executable = try await Model.shared.loadExecutable(url: url)
                            selections.append(.success(executable))
                        } catch {
                            if let loadError = error as? LoadExecutableError {
                                selections.append(.failure(loadError))
                            }
                        }
                    }
                    block?(selections)
                }
            }
        }
    }

}
