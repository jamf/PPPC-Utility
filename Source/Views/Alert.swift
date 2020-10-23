//
//  Alert.swift
//  PPPC Utility
//
//  MIT License
//
//  Copyright (c) 2020 Jamf Software
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

class Alert: NSObject {
    func display(header: String, message: String) {
        DispatchQueue.main.async {
            let dialog: NSAlert = NSAlert()
            dialog.messageText = header
            dialog.informativeText = message
            dialog.alertStyle = NSAlert.Style.warning
            dialog.addButton(withTitle: "OK")
            dialog.runModal()
        }
    }

    /// Displays a message with a cancel button and returns true if OK was pressed
    /// Assumes this method is called from the main queue.
    /// 
    /// - Parameters:
    ///   - header: The header message
    ///   - message: The message body
    /// - Returns: True if the ok button was pressed
    func displayWithCancel(header: String, message: String) -> Bool {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        dialog.addButton(withTitle: "OK")
        dialog.addButton(withTitle: "Cancel")
        let response = dialog.runModal()
        let okPressed = (response.rawValue == 1000)
        return okPressed
    }

}
